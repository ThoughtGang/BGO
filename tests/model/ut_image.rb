#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Image class

require 'test/unit'
require 'bgo/image'

class TC_ImageTest < Test::Unit::TestCase
  TGT_DIR = File.dirname(File.dirname(__FILE__)) + File::SEPARATOR + 'targets'
  TMP = File.join(File.dirname(__FILE__), 'tmp')

  def setup
    Dir.mkdir(TMP) if ! File.exist?(TMP)
  end

  def test_1_image
    fname = TGT_DIR + File::SEPARATOR + 'linux-2.6.x-64.bin'
    cmt = 'a test image'
    File.open(fname, 'rb') do |f|
      buf = f.read
      sha = Digest::SHA1.hexdigest(buf)
      img = Bgo::Image.new(buf)
      img.comment = cmt

      assert_equal(sha, img.ident)
      assert_equal(buf.size, img.size)
      assert_equal(cmt, img.comment.text)
      assert( (not img.virtual?) )

      assert_equal(buf, img.contents)

      assert_equal( buf[0], img[0] )
      assert_equal( buf[1,2], img[1,2] )
      assert_equal( buf[0..1], img[0..1] )
      assert_equal( buf[0...1], img[0...1] )
    end
  end

  def test_2_virtual_image
    # test basic pattern
    img = Bgo::VirtualImage.new( 'a', 10 )
    assert( img.virtual? )
    assert_equal( img.contents, 'aaaaaaaaaa' )
    assert_equal( 'a', img[0] )
    assert_equal( 'aa', img[1,2] )
    assert_equal( 'aa', img[0..1] )
    assert_equal( 'a', img[0...1] )

    # test binary pattern
    img = Bgo::VirtualImage.new( "\000", 5 )
    assert_equal( img.contents, "\000\000\000\000\000" )
    assert_equal( img[0], "\000" )

    # test long pattern
    img = Bgo::VirtualImage.new( '123456', 10 )
    assert_equal( 10, img.contents.length )
    assert_equal( '1234561234', img.contents )
    assert_equal( '1234561234', img[0..-1] )
    assert_equal( '1234561234', img[0,10] )
    assert_equal( '345', img[2..4] )
    assert_equal( '34', img[2...4] )
    assert_equal( '3', img[2] )
  end

  def test_3_remote_image
    # test basic image support
    path = TGT_DIR + File::SEPARATOR + 'linux-2.6.x-64.bin'
    buf = File.binread(path)
    img = Bgo::RemoteImage.new(path)
    assert(img.present?)
    assert_equal(buf, img.contents)

    # test altered image
    path = File.join(TMP, 'linux-2.6.x-64.bin')
    File.binwrite(path, buf)
    orig_img = Bgo::RemoteImage.new(path)
    assert(orig_img.present?)
    buf[0] = "\x00"
    File.binwrite(path, buf)
    assert_raises(RuntimeError) {
      Bgo::RemoteImage.new(path, buf.length, orig_img.ident)
    }

    # test missing image
    File.unlink(path)
    img = Bgo::RemoteImage.new(path, buf.length, orig_img.ident)
    assert(! img.present?)
    str = ([0] * buf.length).pack('C*')
    assert_equal(str, img.contents)
  end

end

