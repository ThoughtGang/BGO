#!/usr/bin/env ruby
# Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO ThreadEvent class

require 'test/unit'
#require 'bgo/thread_event'
# NOTE: This is not implemented yet. These tests serve as a proposed API.

class TC_ThreadEventTest < Test::Unit::TestCase
=begin
  TGT_DIR = File.dirname(File.dirname(__FILE__)) + File::SEPARATOR + 'targets'
  def setup
    Bgo::PluginManager.load_all if Bgo::PluginManager.count < 1
  end

  def test_create
    ident, fname, cmd, cmt = 1000, 'a.out', './a.out -v', 'test run of a.out'
    p = Bgo::Process.new(ident, cmd, fname, nil, cmt)

    assert_equal(ident, p.ident)
    assert_equal(fname, p.filename)
    assert_equal(cmd, p.command)
    assert_equal(cmt, p.comment)
  end

  def test_load
    fname = TGT_DIR + File::SEPARATOR + 'linux-2.6.x-64.bin'
    proj = Bgo::Project.new('bgo_process_test')
    buf = nil
    File.open(fname, 'rb') { |f| buf = f.read }
    img = Bgo::Image.new(buf)
    f = Bgo::TargetFile.new(File.basename(fname), fname, img)
    p = Bgo::Process.new(1000, fname, fname)
    
    plugin = Bgo::PluginManager::find('Objdump').first
    assert( p.load!(f, plugin) )
    assert_equal(2, p.maps.count)
  end

  def test_1_thread_event
  end

  def test_2_logthread_event
  end

  def test_3_statechangethread_event
  end

  def test_4_breakpointthread_event
  end

  def test_5_syscallthread_event
  end
=end
end

