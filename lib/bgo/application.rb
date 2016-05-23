#!/usr/bin/env ruby
# :title: Bgo::Application
=begin rdoc
BGO Application module
Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end 

module Bgo

=begin rdoc
BGO-based applications
=end
  module Application
    autoload :PluginManager, 'bgo/application/plugin_mgr.rb'
    #autoload :DatabaseManager, 'bgo/application/database.rb'
    autoload :ConfigManager, 'bgo/application/config.rb'

=begin rdoc
Declare that the Application uses the specified service. This causes the
Autoload of the service to take place.
=end
    def use(sym); end

=begin rdoc
Convenience method for accessing the ConfigManager via Application.
=end
    def self.config
      ConfigManager.init  # ensure that config manager has been initialized
      ConfigManager
    end

    def config; ConfigManager; end

=begin rdoc
Convenience method for accessing the PluginManager via Application.
=end
    def self.plugins
      PluginManager.init  # Ensure that PluginManager has been initialized
      PluginManager
    end

    def plugins; PluginManager; end

=begin rdoc
A lightweight Application object, used when the core application does not
want to provide its own application class.

Note that this Application object will not start any services.
=end
    def self.lightweight
      obj = Object.new
      obj.extend Application
      obj
    end

  end
end
