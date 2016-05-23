#!/usr/bin/env ruby
# :title: Bgo::Application::ConfigManager
=begin rdoc
BGO Config Manager

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

require 'yaml'

require 'bgo/application/env'
require 'bgo/application/service'

module Bgo

  module Application

=begin rdoc
An application service for managing configuration and preferences.
=end
    class ConfigManager
      extend Service

      # Name of directory where config files are stored
      DEFAULT_APP_DIR = 'bgo'           # bgo or .bgo
      @app_dir = DEFAULT_APP_DIR

      # Name of config file for BGO framework. This is the main config file.
      FRAMEWORK_CONFIG = 'framework'    # framework.yaml

      @config_files = {}
      @initialized = false

=begin rdoc
Read the framework config file.
=end
      def self.init
        read_config(FRAMEWORK_CONFIG) if ! @initialized
        @initialized = true
      end

=begin rdoc
This should be invoked after an application has completed startup.
=end
      def self.startup(app); end # nothing to do

=begin rdoc
=end
      def self.object_loaded(app, obj)
        obj.read_config(self) if obj.respond_to? :read_config
      end

=begin rdoc
This should be invoked after an application is about to commence shutdown.
=end
      def self.shutdown(app); end  # nothing to do: apps handle config writes

=begin rdoc
Return default configuration directory. This is the directory 'application/conf'
under the BGO install tree.
=end
      def self.get_default_dir
          File.join(File.dirname(__FILE__), 'conf')
      end

=begin rdoc
Return application config directory in system conf dir (/etc).
=end
      def self.get_system_dir
        # FIXME: if win32
        File.join('', 'etc', @app_dir, 'conf')
      end

=begin rdoc
Return application config directory in user home dir (~).

Note: The home directory is obtained form the environment variable HOME.
=end
      def self.get_home_dir
        # FIXME: if win32
        ENV['HOME'] ? File.join(ENV['HOME'], '.' + @app_dir, 'conf') : nil
      end

=begin rdoc
Return working directory (.)
=end
      def self.get_wd
        # FIXME: if win32
        '.'
      end

=begin rdoc
Return conf directory specified in BGO_CONFIG environment variable, if any.
=end
      def self.get_env
        (Env.set? Env::CONFIG) ? ENV[Env::CONFIG] : nil
      end

      # install_dir + system dir + home dir
=begin rdoc
Return Array of conf directories. This is built in the following order (later
conf files override earlier ones):
  1. INSTALL DIR : [BGO_BASE]/lib/bgo/application/conf 
  2. SYSTEM DIR : /etc/bgo/conf
  3. HOME DIR : ~/.bgo/conf
  4. WORKING DIR : .
  5. ENV : obtained from BGO_CONFIG environment variable
=end
      def self.config_dirs
        @config_dirs ||= [ get_default_dir, get_system_dir, get_home_dir, 
                          get_wd, get_env ].reject{ |dir| ! dir || dir.empty? }
      end

      def self.set_app_dir(name)
        @app_dir = name
      end

      def self.read_framework_config
        read_config('bgo-framework')
      end

      def self.read_config(cfg_name)
        name = File.basename(cfg_name)

        @config_files[name] = {} if not @config_files[name]
        config_dirs.each do |d|
          path = File.join(d, name + '.yaml')
          @config_files[name].merge!(read_config_file(path))
        end
        @config_files[name]
      end

      def self.read_config_file(path)
        (File.exist? path) ? YAML.load_file(path) : {}
      end

=begin rdoc
Return the config Hash objects for the named sections [e.g. 'plugins'].
=end
      def self.[](*args)
        @config_files.[](*args) || {}
      end

      # TODO: is this even useful?
      #def self.[]=(*args)
      #  @config_files.[]=(*args)
      #end

=begin rdoc
Return the config Hash object for the BGO framework.
=end
      def self.framework
        @config_files[FRAMEWORK_CONFIG] || {}
      end

    end

  end
end
