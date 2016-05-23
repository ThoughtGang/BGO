#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO-Git use of BGO data model

require 'rubygems'
require 'bgo/application/git/project'

require 'test/unit'
require 'fileutils'

require_relative '../shared/project'

# TODO: test modified?, close/save, etc

class TC_GitModelTest < Test::Unit::TestCase
  TMP = File.join(File.dirname(__FILE__), 'tmp')
  PROJ_1_FNAME = 'Test Project 1'
  PROJ_1_NAME = 'bgo_proj1_test'
  PROJ_1_DESCR = 'Test of Bgo::Git::Project.create method w/o block'
  PROJ_1_PATH = File.join(TMP, PROJ_1_FNAME)
  PROJ_2_NAME = 'Test Project 2'
  PROJ_2_FNAME = 'bgo_proj2_test'
  PROJ_2_PATH = File.join(TMP, PROJ_2_FNAME)
  PROJ_2_DESCR = 'Test of Bgo::Git::Project.create method with block'

  def setup
    Dir.mkdir(TMP) if ! File.exist?(TMP)
  end

  # print repo contents to stderr for debugging
  def print_project_tree(path)
    print_project_subdir path, 'json'
    print_project_subdir path, 'image'
    print_project_subdir path, 'file'
    print_project_subdir path, 'process'
    print_project_subdir path, 'tag'
  end

  def print_project_subdir(path, subdir)
    $stderr.puts `find '#{File.join path, subdir}'`
  end

  def test_1_create
    # without block
    Bgo::Git::Project.create(PROJ_1_PATH, PROJ_1_NAME, PROJ_1_DESCR)

    assert( File.exist? File.join(PROJ_1_PATH, Bgo::Git::Project::FILE_JSON) )
    assert( File.exist? File.join(PROJ_1_PATH, '.git', 'bgo') )
    assert( File.directory? File.join(PROJ_1_PATH, Bgo::Git::Project::DIR_IMG))
    assert( File.directory? File.join(PROJ_1_PATH, Bgo::Git::Project::DIR_FILE))
    assert( File.directory? File.join(PROJ_1_PATH, Bgo::Git::Project::DIR_PROC))
    assert( File.directory? File.join(PROJ_1_PATH, Bgo::Git::Project::DIR_TAG))

    Dir.chdir(PROJ_1_PATH) { 
      v = `git config #{Bgo::Git::Project::BGO_VERSION_CFG}`.chomp
      assert_equal(Bgo::VERSION.to_s, v)
    }

    # with block
    ENV['BGO_AUTHOR_NAME'] = 'unit_test'
    ENV['BGO_AUTHOR_EMAIL'] = 'unit_test@example.com'
    p = Bgo::Git::Project.create(PROJ_2_PATH, PROJ_2_NAME) do |p|
      p.descr = PROJ_2_DESCR

      assert( File.exist?(File.join(PROJ_2_PATH,Bgo::Git::Project::FILE_JSON)))
      assert( File.exist? File.join(PROJ_2_PATH, '.git', 'bgo') )

      assert_equal(File.absolute_path(PROJ_2_PATH), p.top_level)
      p.comment = 'COMMENT!'
      p.properties[:test] = ['a', 'b', 'c']
      p.set_comment('123456', :ut)
      p.set_comment('654321', :ut, 'nobody')
      p.tag(:unit_test)
    end

    assert_equal(ENV['BGO_AUTHOR_NAME'], p.current_author)
    assert_equal(ENV['BGO_AUTHOR_NAME'], p.actor.name)
    assert_equal(ENV['BGO_AUTHOR_EMAIL'], p.actor.email)
    assert_equal('COMMENT!', p.comment.text)
    assert_equal({:test => ['a','b','c']}, p.properties)
    assert_equal('123456', p.comments[:ut][p.current_author].text)
    assert_equal('654321', p.comments[:ut]['nobody'].text)
  end

  def test_2_open
    p = Bgo::Git::Project.open(PROJ_1_PATH)
    assert(p.kind_of? Bgo::Project)
    assert(p.kind_of? Bgo::Git::Project)

    Test::Project.fill_images(p)
    assert_equal(2, p.images.count)

    Test::Project.fill_files(p)
    assert_equal(1, p.files.count)
    f = p.files.first
    assert_equal(2, f.sections.count)
    s = f.sections.first
    assert_equal(1, s.addresses.count)

    Test::Project.fill_processes(p)
    assert_equal(1, p.processes.count)
    pp = p.processes.first
    assert_equal(2, pp.maps.count)
    m = pp.maps.first
    assert_equal(1, m.addresses.count)
    p.close

    # To test repo generation:
    print_project_tree PROJ_1_PATH

    p = Bgo::Git::Project.open(PROJ_1_PATH)
    assert_equal(2, p.images.count)
    it = p.images
    img_ident = it.next.ident
    vimg_ident = it.next.ident
    # check that file serialized correctly
    assert_equal(1, p.files.count)
    f = p.files.first
    assert_equal(2, f.sections.count)
    s = f.sections.first
    assert_equal(1, s.addresses.count)
    # check that process serialized correctly
    assert_equal(1, p.processes.count)
    pp = p.processes.first
    assert_equal(2, pp.maps.count)
    m = pp.maps.first
    assert_equal(1, m.addresses.count)
    p.close

    Bgo::Git::Project.open(PROJ_1_PATH) do |p|
      img = p.image(img_ident)
      assert(img.kind_of? Bgo::Image)
      assert(img.kind_of? Bgo::Git::Image)

      img = p.image(vimg_ident)
      assert(img.kind_of? Bgo::Image)
      assert(img.kind_of? Bgo::VirtualImage)
      assert(img.kind_of? Bgo::Git::VirtualImage)

      p.remove_image(vimg_ident)

      # TODO: remove file
      # TODO: remove process
      # TODO: remove section
      # TODO: remove map
    end

    Bgo::Git::Project.open(PROJ_1_PATH) do |p|
      assert_equal(1, p.images.count)
      assert_equal(img_ident, p.images.first.ident)
    end
  end

  def old_test_3_config
    assert_equal('', @proj.config['the test'], 'Test cfg entry not empty')
    assert_equal('model-testproject.the-test', @proj.config.path('the test'), 
                 'Config object generated wrong path')
    @proj.config['the test'] = 'zyx'
    assert_equal('zyx', @proj.config['the test'], 'Cfg string incorrect')
  end

  def old_test_3_actor
    #actor, set_author, actor=
  end

  def old_test_4_save
    proj = Bgo::Git::Project.open(@proj.top_level)
    name = 'saved_project_name'
    proj.save("v1") do |options|
      proj.name=(name)
    end

    p = Bgo::Git::Project.open(proj.top_level)
    assert_equal(name, p.name)
  end

  def test_9_delete
    FileUtils.remove_dir(PROJ_1_PATH) if File.exist?(PROJ_1_PATH)
    FileUtils.remove_dir(PROJ_2_PATH) if File.exist?(PROJ_2_PATH)
  end

end
