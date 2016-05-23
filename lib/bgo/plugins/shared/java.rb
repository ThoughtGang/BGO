#!/usr/bin/env jruby                                                            
# :title: Java support
=begin rdoc
Support for plugins that call Java modules
Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

raise ScriptError.new("Plugin requires JRuby") unless RUBY_PLATFORM =~ /java/

require 'java'

module Bgo
  module Plugins

=begin rdoc
Namespace containing Java support methods.
=end
    module Java

=begin rdoc
Load the specified Java module (usually a .jar).
Note that this requires the module to be in the load path.
=end
      def self.import(path)
        # TODO: fix this to use 'load' and access the path directly?
        require path
      end
      
    end
  end
end
