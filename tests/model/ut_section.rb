#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Section class

require 'test/unit'
require 'bgo/section'

class TC_SectionTest < Test::Unit::TestCase

  def test_create
    fname = '/tmp/a.out'
    buf = "\x00\x00\x00\x00\xCC\xCC\xCC\xCC\xFF\xFF\xEE\xEE\xDD\xDD\xBB\xBB"
    img = Bgo::Image.new(buf)
    f = Bgo::TargetFile.new(File.basename(fname), fname, img)

    ident, name, offset, size, cmt = "1", '.ctor', 0, 4, 'fake ctor'
    flags = [ Bgo::Section::FLAG_READ, Bgo::Section::FLAG_EXEC ]
    sec = Bgo::Section.new(ident, name, img, f.image_offset + offset, offset, 
                           size, flags)
    sec.comment = cmt

    assert_equal(ident, sec.ident)
    assert_equal(name, sec.name)
    assert_equal(offset, sec.offset)
    assert_equal(size, sec.size)
    assert_equal(cmt, sec.comment.text)
    assert_equal(f.image.size, sec.image.size)
    assert_equal(f.image.ident, sec.image.ident)
  end

end

