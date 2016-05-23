#!/usr/bin/env jruby                                                            
# :title: Python support
=begin rdoc
Support for plugins that call Python modules
Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'rubygems'
require "rubypython"

module Bgo
  module Plugins

=begin rdoc
Namespace containing Python support methods.
=end
    module Python

=begin rdoc
Return true if Python subsystem is already running.
=end
      def self.running?
        $BgoPythonRunning
      end

=begin rdoc
Start Python subsystem if it is not already running.
=end
      def self.start
        start! if (! running?)
      end


=begin rdoc
Start Python subsystem unconditionally.
=end
      def self.start!
        RubyPython.start
        $BgoPythonRunning = true
      end

=begin rdoc
Stop Python subsystem if it is already running.
=end
      def self.stop
        stop! if (running?)
      end


=begin rdoc
Stop Python subsystem unconditionally.
=end
      def self.stop!
        RubyPython.stop
        $BgoPythonRunning = false
      end

=begin rdoc
Restart Python subsystem.
=end
      def self.restart
        stop
        start
      end

=begin rdoc
Import Python module at 'path'. This returns the module object.
=end
      def self.import(path)
        RubyPython.import(path)
      end
    end
  end
end

# Start Python subsystem when this module is initially loaded.
Bgo::Plugins::Python.start
