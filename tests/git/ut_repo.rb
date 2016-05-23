#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO-Git Repo class

require 'rubygems'
require 'bgo/application/git/repo'

require 'test/unit'
require 'fileutils'

class TC_GitRepoTest < Test::Unit::TestCase
  TMP = File.join(File.dirname(__FILE__), 'tmp')
  REPO_1_PATH = File.join(TMP, 'repo_1')

  def setup
    Dir.mkdir(TMP) if ! File.exist?(TMP)
  end

  def test_1_create
    r = Bgo::Git::Repo.create(REPO_1_PATH)
    assert(r.kind_of? Bgo::Git::Repo)
    assert(r.kind_of? Grit::Repo)
    assert_equal(File.absolute_path(REPO_1_PATH), r.top_level)
  end


  def test_9_delete
    FileUtils.remove_dir(REPO_1_PATH) if File.exist?(REPO_1_PATH)
    #FileUtils.remove_dir(REPO_2_PATH) if File.exist?(REPO_2_PATH)
  end

end
