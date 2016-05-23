#!/usr/bin/env ruby                                                             
# :title: Bgo::Commands::Plugin
=begin rdoc
Utility methods for using Plugins in Commands.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'rubygems'
require 'json/ext'

module Bgo
  module Commands

=begin rdoc
Add standard plugin options to options parser.
=end
    def self.plugin_options(options, opts)
      options.plugin = nil
      options.plugin_opts = {}
      opts.on( '-u', '--use-plugin string' ) { |str| options.plugin = str }
      opts.on( '', '--plugin-options string' ) { |str| options.plugin_opts = 
                                                 decode_plugin_options(str) }
    end

=begin rdoc
Return usage string for plugin options.
=end
    def self.plugin_usage; "[-u name]"; end

=begin rdoc
Return help string for plugin options.

Note: This will raise a NameError if PluginManager service has not been started.
=end
    def self.plugin_options_help
"Plugin options:
  -u, --use-plugin string   Name or canon_name of plugin to use
      --plugin-options      JSON-encoded Hash of options to send to plugin"
    end

    #def self.plugin_help
    #end

=begin rdoc
Return plugin for 'name', or fittest plugin providing 'spec' if name is nil.

Note: This will raise exceptions if a suitable plugin is not found.
=end
    def self.plugin_for_spec(spec, name, *args)
      p = name ? Bgo::Application::PluginManager.find(name) :
                 Bgo::Application::PluginManager.fittest_providing(spec, *args)
      raise "No plugin found for name #{name}" if name && ! p
      raise "No plugin found for spec #{spec.to_s}" if ! p
      raise "Plugin #{name} does not provide spec #{spec.to_s}" if p &&
            (! p.spec_supported? spec)
      p
    end

=begin rdoc
Decode a plugin options Hash from an options string. Note that plugin options
should be a JSON-serialized hash.
=end
    def self.decode_plugin_options(str)
      JSON.parse(str, :symbolize_names => true)
    end

  end
end
