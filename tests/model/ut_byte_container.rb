#!/usr/bin/env ruby
# Copyright 2011 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO ByteContainer class

require 'test/unit'
require 'bgo/image'
require 'bgo/byte_container'

class TC_ByteContainerTest < Test::Unit::TestCase

  def test_create
    buf = "\x00\x00\x00\x00\xCC\xCC\xCC\xCC\xFF\xFF\xEE\xEE\xDD\xDD\xBB\xBB"
    img = Bgo::Image.new(buf)

    vma, offset, size = 0, 0, 4
    ai = Bgo::ArchInfo.new('i386', 'x86-64', Bgo::ArchInfo::ENDIAN_LITTLE)
    obj = Bgo::ByteContainer.new(img, vma, offset, size, ai)

    assert_equal(vma, obj.start_addr)
    assert_equal(offset, obj.offset)
    assert_equal(size, obj.size)
  end

end

