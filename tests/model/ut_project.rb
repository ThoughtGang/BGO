#!/usr/bin/env ruby
# Copyright 2010 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Project class

require 'bgo/project'

require 'test/unit'
require_relative '../shared/project'

$proj = nil
class TC_ProjectTest < Test::Unit::TestCase
  def test_1_create
    p = Bgo::Project.new
    assert_equal(Bgo::Project::DEFAULT_NAME, p.name, 'Default name not used')
    assert_equal(Bgo::Project::DEFAULT_DESCR, p.description, 
                 'Default description not used')
    assert_equal(Bgo::VERSION, p.bgo_version, 'BGO Version is wrong')

    name, descr = 'TestProject', 'A test project'
    p = Bgo::Project.new(name, descr)
    assert_equal(name, p.name, 'Specified name not used')
    assert_equal(descr, p.description, 'Specified description not used')

    descr2 = 'Not really a test project'
    p.description = descr2
    assert_equal(descr2, p.description, 'Updated description not used')

    name = 'UT-Project'
    descr = 'A project for unit testing of in-memory model'
    $proj = Bgo::Project.new name, descr
    assert_equal(name, $proj.name)
    assert_equal(descr, $proj.descr)
  end

  def test_2_images
    Test::Project.fill_images($proj)
    #assert( img.kind_of? Bgo::Image )
    #assert_equal( binstr.length, img.size )
    # TODO: list, instantate, delete
  end

  def test_3_files
    Test::Project.fill_files($proj)
    #assert( f.kind_of? Bgo::TargetFile )
    #assert_equal( img.size, f.size )
  end

  def test_4_processes
    Test::Project.fill_processes($proj)
    #assert( p.kind_of? Bgo::Process )
    # TODO: map file into process
  end

  def test_9_json
    $proj.to_json
    # TODO: actually check JSON output
    #puts str.inspect
  end

  # TODO: ident open close subscribers comments tags
end

