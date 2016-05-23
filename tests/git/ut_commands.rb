#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO-Git interaction with BGO Commands

require 'bgo/application/command'
require 'bgo/application/git/project'

require 'test/unit'
require 'fileutils'

#require_relative '../shared/project'

# TODO: additional commands: create process, map, etc

class TC_GitCommandTest < Test::Unit::TestCase
  TMP = File.join(File.dirname(__FILE__), 'tmp')
  PROJ_1_FNAME = 'git_command_test.bgo'
  PROJ_1_NAME = 'Bgo-Git Test'
  PROJ_1_DESCR = 'Test interaction between BGO and BGO-Git'
  PROJ_1_PATH = File.join(TMP, PROJ_1_FNAME)

  def setup
    Dir.mkdir(TMP) if ! File.exist?(TMP)
  end

  def test_1_project_create
    new_cmd = Bgo::Application::Command.load_single('project-create')
    assert_not_nil(new_cmd)

    path = TMP + ::File::SEPARATOR + 'new_project_anon'
    new_cmd.invoke( ['-d', PROJ_1_DESCR, '-n', PROJ_1_NAME, PROJ_1_PATH] )
    assert(File.exist? PROJ_1_PATH)
    Bgo::Git::Project.open(PROJ_1_PATH) do |p|
      assert_equal(PROJ_1_NAME, p.name)
      assert_equal(PROJ_1_DESCR, p.description)
    end

    # example of obtaining state from command:
    # cmd = Bgo::Application::Command.load_single('project')
    # assert_not_nil(cmd)
    # s = cmd.invoke_returning_state(['-n', '-p', PROJ_1_PATH])
    # $stderr.puts s.inspect
  end

  def test_9999_cleanup
    FileUtils.remove_dir(PROJ_1_PATH) if File.exist?(PROJ_1_PATH)
  end
end
