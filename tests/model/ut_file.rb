#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO File class

require 'test/unit'
require 'bgo/image'
require 'bgo/file'

class TC_FileTest < Test::Unit::TestCase
  TGT_DIR = File.dirname(File.dirname(__FILE__)) + File::SEPARATOR + 'targets'

  def test_create
    fname = TGT_DIR + File::SEPARATOR + 'linux-2.6.x-64.bin'
    buf = File.binread(fname)

    img = Bgo::Image.new(buf)
    f = Bgo::TargetFile.new(File.basename(fname), fname, img)

    assert_equal(fname, f.full_path, 'Invalid file name')
    assert_equal(File.basename(fname), f.name, 'Invalid file name')
    assert_equal(File.dirname(fname), f.dir, 'Invalid file name')
    img = f.image
    assert_equal(Digest::SHA1.hexdigest(buf), f.digest, 'Invalid digest')

    f.open do |fh|
      f_buf = fh.read
      assert_equal(buf, f_buf, 'File.open fails')
    end
  end

  def test_nesting
    buf = "\x00\x00\x00\x00\x90\x90\x90\x90\x90\x90\xCC\xCC\xCC\xCC\x00\x00\x00"
    img = Bgo::Image.new(buf)
    f = Bgo::TargetFile.new('t.ar', '/tmp/t.ar', img)

    # manual creation of contained files
    f1 = Bgo::TargetFile.new('child_1', 'child_1', img, 4, 6)
    assert_equal(buf[4,6], f1.contents)
    f2 = Bgo::TargetFile.new('child_2', 'child_2', img, 10, 4)
    assert_equal(buf[10,4], f2.contents)

    # proper creation of contained files
    assert_equal(0, f.files.count)
    f1 = f.add_file( 'child_1', 'child_1', 4, 6)
    assert_equal(1, f.files.count)
    assert_equal(buf[4,6], f1.contents)
    assert_equal(f1.name, f.file('child_1').name)
    f2 = f.add_file( 'child_2', 'child_2', 10, 4)
    assert_equal(2, f.files.count)
    assert_equal(buf[10,4], f2.contents)
    assert_equal(f2.name, f.file('child_2').name)
  end

end

