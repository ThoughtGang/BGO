#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Address class

require 'test/unit'
require 'bgo/address'
require 'bgo/image'

# TODO: symbol binding
# TODO: references

class TC_AddressTest < Test::Unit::TestCase

  def test_create
    buf = "\x00\x00\x00\x00\xCC\xCC\xCC\xCC\xFF\xFF\xEE\xEE\xDD\xDD\xBB\xBB"
    img = Bgo::Image.new(buf)

    a1 = Bgo::Address.new(img, 4, 4 )
    assert_equal(buf[4,4].bytes.to_a, a1.bytes.to_a)
    assert_equal(buf[4,4], a1.contents)
    assert_equal(4, a1.offset)
    assert_equal(4, a1.vma)
    assert_equal(7, a1.end_vma)
    assert_equal(4, a1.size)
    assert_equal(Bgo::Address::CONTENTS_UNK, a1.content_type)
    assert( a1.data? )
    assert( (not a1.code?) )

    v1 = Bgo::Address.new(img, 4, 4, 0x1004 )
    assert_equal(buf[4,4].bytes.to_a, v1.bytes.to_a)
    assert_equal(4, v1.offset)
    assert_equal(0x1004, v1.vma)
    assert_equal(0x1007, v1.end_vma)
    assert_equal(4, v1.size)
    assert_equal(Bgo::Address::CONTENTS_UNK, v1.content_type)
    assert( v1.data? )
    assert( (not v1.code?) )

    a2 = Bgo::Address.new(img, 8, 2 )
    assert_equal(buf[8,2].bytes.to_a, a2.bytes.to_a)
    assert_equal(8, a2.offset)
    assert_equal(8, a2.vma)
    assert_equal(9, a2.end_vma)
    assert_equal(2, a2.size)
    assert_equal(Bgo::Address::CONTENTS_UNK, a2.content_type)
    assert( a2.data? )
    assert( (not a2.code?) )

    a3 = Bgo::Address.new(img, 12, 4 )
    assert_equal(buf[12,4].bytes.to_a, a3.bytes.to_a)
    assert_equal(12, a3.offset)
    assert_equal(12, a3.vma)
    assert_equal(15, a3.end_vma)
    assert_equal(4, a3.size)
    assert_equal(Bgo::Address::CONTENTS_UNK, a3.content_type)
    assert( a3.data? )
    assert( (not a3.code?) )

    # test Address Space
    addrs = Bgo::Address.address_space( [a1, a2, a3], img, 0, 4 )
    assert_equal( 4, addrs.count )
    assert_equal( a1.vma, addrs[0].vma )
    assert_equal( a2.vma, addrs[1].vma )
    assert_equal( 10, addrs[2].vma )
    assert_equal( 2, addrs[2].size )
    assert_equal( a3.vma, addrs[3].vma )

    addrs = Bgo::Address.address_space( [a1, a2, a3], img, 0 )
    assert_equal( 5, addrs.count )
    assert_equal( 0, addrs[0].vma )
    assert_equal( 4, addrs[0].size )
    assert_equal( a1.vma, addrs[1].vma )
    assert_equal( a2.vma, addrs[2].vma )
    assert_equal( 10, addrs[3].vma )
    assert_equal( 2, addrs[3].size )
    assert_equal( a3.vma, addrs[4].vma )

    addrs = Bgo::Address.address_space( [v1], img, 0x1000 )
    assert_equal( 3, addrs.count )
    assert_equal( 0x1000, addrs[0].vma )
    assert_equal( 4, addrs[0].size )
    assert_equal( v1.vma, addrs[1].vma )
    assert_equal( 0x1008, addrs[2].vma )
    assert_equal( 8, addrs[2].size )
  end

  def test_names
  end

  def test_references
  end

end

