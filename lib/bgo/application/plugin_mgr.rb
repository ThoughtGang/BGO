#!/usr/bin/env ruby
# :title: Bgo::PluginManager
=begin rdoc
BGO Plugin Manager

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'tg/plugin.rb'
require 'tg/plugin_mgr.rb'
#require 'bgo/plugins/shared/specification'
require 'bgo/application'
require 'bgo/application/config'
require 'bgo/application/service'

module Bgo

  module Application

=begin rdoc
An application service for managing plugins. There are two main reponsibilities
of the service: finding and loading ('read') Ruby module files that contain
Plugin classes, and instantiating ('load') those classes. Additional features
include conveying notifications between the application and the plugins,
resolving Plugin dependencies, and listing or finding Plugins.

The PluginManager acts as a singleton; everything is handled through class
members and class methods. Many functions are delegates for Plugin class 
methods.

Note: The PluginManager loads all plugins during init. This allows Plugins to
to be made available to all Application Services when the startup signal is
sent. The loading of all available plugins should be considered 
'initialization'; once loaded, plugins will receive a startup signal.
=end
    class PluginManager < TG::PluginManager
      extend Service

      @initialized = false

      # ----------------------------------------------------------------------
=begin rdoc
Initialize the Plugin Manager.
This reads the ruby modules in all plugin directories, then loads all plugins 
that are not blacklisted.
=end
      def self.init
        return if @initialized

        read_config
        app_init

        @initialized = true
      end

=begin rdoc
Read configuration for plugins from Application config.
=end
      def self.read_config

        # Plugins are in directories names bgo/plugins in Ruby module path
        add_base_dir( File.join('bgo', 'plugins') )

        # Get plugin directories from config file
        @config = Application.config.read_config(CONF_NAME)
        if @config['plugin_dirs']
          @config['plugin_dirs'].split(':').reverse.each {|p| add_plugin_dir p}
        end

        # Set TG_PLUGIN_DEBUG from environment variable
        $TG_PLUGIN_DEBUG = true if (Env.set? Env::PLUGIN_DEBUG)

        # Get plugin directories from environment variable
        if (Env.set? Env::PLUGINS)
          ENV[Env::PLUGINS].split(':').reverse.each {|p| add_plugin_dir p}
        end

        # Read in blacklisted files and plugins from config file
        if @config['blacklist']
          @config['blacklist'].split(':').each { |p| blacklist(p) }
        end
        if @config['blacklist_files']
          @config['blacklist_files'].split(':').each { |p| blacklist_file(p) }
        end

        # Read in blacklisted files and plugins from environment variable
        if (Env.set? Env::PLUGIN_BLACKLIST)
          ENV[Env::PLUGIN_BLACKLIST].split(':').each { |p| blacklist(p) }
        end
        if (Env.set? Env::PLUGIN_FILE_BLACKLIST)
          ENV[Env::PLUGIN_FILE_BLACKLIST].split(':').each { |p| 
            blacklist_file(p) }
        end

        # load built-in specifications
        spec_dir = File.join( File.dirname(File.dirname(__FILE__)),
                              'plugins/shared/specification' )
        load_specification_dir spec_dir
      end

      def self.startup(app); app_startup(app); end
      def self.object_loaded(app, obj); app_object_loaded(app, obj); end
      def self.shutdown(app); app_shutdown(app); end

=begin rdoc
Convenience method for testing: runs PluginManager init() and startup(), with
Application.lightweight as a parameter.
=end
      def self.standalone
        self.init
        self.startup Application.lightweight
      end

=begin rdoc
Invoke Plugin implementation of Specification on args. If plugin is a String,
it will be passed to PluginManager.find; if it is nil, the Plugin with the
highest score for this spec will be chosen. The args Array is passed directly
to the Plugin Specification block and method. The score for the Specification
is discarded.

The return value is that of the Specification, or nil if a suitable plugin 
could not be found.
=end
      def self.invoke_spec(spec, plugin, *args)
        sym = spec.to_sym
        p = plugin ? find(plugin) : fittest_providing(sym, *args)
        p ? p.spec_invoke(sym, *args) : nil
      end
    end

  end
end
