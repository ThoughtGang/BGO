#!/usr/bin/env ruby
# :title: BGO::Application::Service
=begin rdoc
BGO base class for Application services

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

module Bgo

  module Application

=begin rdoc
A singleton (i.e. module, non-instantiated class.

Example:

  class TheApplication
    include Bgo::Application

    def initialize(argv)
      # ... init code ...
      Service.init_services
    end

    def run
      Service.startup_services(self)
      # ... event loop ...
      Service.shutdown_services(self)
    end

    def new_project_window(proj)
      # ... create a new project window ...
      Service.broadcast_object_loaded(self, proj)
    end
=end
    module Service

      @service_classes = []

      def self.extended(cls)
        if ! (@service_classes.include? cls)
            @service_classes << cls
        end
      end

=begin rdoc
Invoke the init class method for every registered service.

Note: the Service.init method does not take an Application object parameter.
This forces all Services that require Application members (e.g. ConfigManager 
or PluginManager services) to go through the Application class itself, rather
than an Application class instance. This is because a) the Application object
is not considered "initialized" until the Services have all been initialized,
and b) the Application object will provide sane defaults (including 
initializing ConfigManager or PluginManager if necessary).
=end
      def self.init_services
        @service_classes.each { |cls| cls.init }
      end

      # default implementation of init class method: no-op
      def self.init(); end

=begin rdoc
This should be invoked after an application has completed startup.
=end
      def self.startup_services(app)
        @service_classes.each { |cls| cls.startup app }
      end

      # default implementation of startup class method: no-op
      def self.startup(app); end

=begin rdoc
=end
      def self.broadcast_object_loaded(app, obj)
        @service_classes.each { |cls| cls.object_loaded(app, obj) }
      end

      # default implementation of object-loaded class method: no-op
      def self.object_loaded(app, obj); end

=begin rdoc
This should be invoked after an application is about to commence shutdown.
=end
      def self.shutdown_services(app)
        @service_classes.each { |cls| cls.shutdown app }
        ::Process.waitall
      end

      # default implementation of shutdown class method: no-op
      def self.shutdown(app); end

    end

  end
end
