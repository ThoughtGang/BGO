#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO project commands

require 'test/unit'
require 'bgo/application/command'
require 'bgo/application/git/project'

class TC_CommandProject < Test::Unit::TestCase

  def test_1_project
    # project-create command
    new_cmd = Bgo::Application::Command.load_single('project-create')
    assert_not_nil(new_cmd)
    assert_equal('project-create', new_cmd.command_name)
    assert_equal('Create a new BGO Project', new_cmd.summary)
    assert_equal('[-p name] [-n str] [-d str] [PATH]', new_cmd.usage)

    # create an anonymous project
    state = new_cmd.invoke_returning_state([])
    p = state.project
    assert_equal(Bgo::Project::DEFAULT_NAME, p.name)
    assert_equal(Bgo::Project::DEFAULT_DESCR, p.description)

    # create a named project
    name = 'a simple project'
    descr = 'a detailed description'
    state = new_cmd.invoke_returning_state(['-n', name, '-d', descr])
    p = state.project
    assert_equal(name, p.name)
    assert_equal(descr, p.description)
  end

end

