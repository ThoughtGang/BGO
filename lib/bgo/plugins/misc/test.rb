#!/usr/bin/env ruby
# :title: Bgo::Plugins::Test
=begin rdoc
Test plugin to ensure that PluginManager is working.
(c) Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end
 
require 'tg/plugin'

module Bgo
  module Plugins
    module Test

      class TestPlugin
        extend TG::Plugin

        name 'test-echo'
        author 'dev@thoughtgang.org'
        version '1.0'
        description 'A plugin to test the plugin system'
        help 'This plugin is only intended for testing the Plugin subsystem.
It echoes its input to STDOUT.'

        def echo(str)
          $stdout.puts str
        end
      end

    end
  end
end

if __FILE__ == $0

  p = Bgo::Plugins::Test::TestPlugin.new
  p.echo "Hello from #{p.canon_name}"

end
