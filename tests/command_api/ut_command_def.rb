#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Command definition API.

require 'test/unit'
require 'bgo/application/command'

class TC_PluginTest < Test::Unit::TestCase

  CMD_NAME = 'test-command'
  Bgo::Application::Command.load_internal(CMD_NAME)
  class TestCommand < Bgo::Application::Command
    summary 'A command for unit testing'
    usage '-h'
    help 'There is no help for this command'

    def self.invoke(args)
      args.inject(0) { |i, sum| sum + i }
    end
  end

  def test_command_definition
    cmd_list = Bgo::Application::Command.commands
    assert_equal( cmd_list.length, 1 )
    assert_equal( cmd_list[0], CMD_NAME )

    assert_equal( 6, Bgo::Application::Command.run(CMD_NAME, 1, 2, 3) )
    assert_equal( 1111, 
                  Bgo::Application::Command.run(CMD_NAME, 1, 10, 100, 1000) )
  end

end

