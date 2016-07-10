#!/usr/bin/env jruby                                                            
# :title: Python support
=begin rdoc
Support for plugins that call Python modules
Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'rubygems'
require "rubypython"

# first, fix RubyPython
class RubyPython::Interpreter
  alias :find_python_lib_orig :find_python_lib

  def find_python_lib
    @libbase = "#{::FFI::Platform::LIBPREFIX}#{@version_name}"
    @libext = ::FFI::Platform::LIBSUFFIX
    @libname = "#{@libbase}.#{@libext}"

    # python-config --confdir provides location of .so 
    config_util = "#{version_name}-config"
    confdir = %x(#{config_util} --configdir).chomp

    library = File.join(confdir, @libname)
    if (File.exist? library)
      @locations = [ library ]
    else
      library = find_python_lib_orig
    end

    library
  end
end

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
