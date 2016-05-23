#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO AddressContainer class

require 'test/unit'
require 'bgo/image'
require 'bgo/address_container'

class TC_AddressContainerTest < Test::Unit::TestCase

  def test_01_create_revise_patch
    buf = "\x00\x00\x00\x00\xCC\xCC\xCC\xCC\xFF\xFF\xEE\xEE\xDD\xDD\xBB\xBB"
    img = Bgo::Image.new(buf)

    # TODO: img, vma, offset, size
    ac = Bgo::AddressContainer.new( img )
    assert_equal(0, ac.current_revision)
    assert_equal(img.ident, ac.base_image.ident)
    assert_equal(img.ident, ac.image.ident)
    assert_equal(1, ac.revisions.count)

    # add address
    ac.add_address(0, 1)
    ac.add_address(1, 2)
    ac.add_address(3, 1)
    ac.add_address(4, 4)
    ac.add_address(8, 2)
    assert_equal(5, ac.addresses.count)
    # add revision
    rev = ac.add_revision
    assert_equal(1, ac.current_revision)
    assert_equal(2, ac.revisions.count)
    ac.add_address(0, 4)
    ac.add_address(10, 2, 0)
    ac.add_address(12, 2)
    ac.add_address(14, 2)
    assert_equal(6, ac.addresses.count)
    assert_equal(6, ac.addresses(1).count)
    assert_equal(3, ac.addresses(1, false).count)
    assert_equal(3, ac.addresses(nil, false).count)
    assert_equal(6, ac.addresses(0, false).count)
    assert_equal(6, ac.addresses(0).count)
    # remove address
    ac.remove_address(12)
    ac.remove_address(14)
    assert_equal(1, ac.addresses(nil, false).count)
    ac.remove_address(10, 0)
    assert_equal(5, ac.addresses(0).count)
    ac.remove_revision(1)
    assert_equal(1, ac.revisions.count)
    assert_equal(0, ac.current_revision)
    # add patch
    ac.add_revision
    assert_equal(1, ac.current_revision)
    ac.patch_bytes(0, "\x11\x22\x33")
    ac.add_address(0, 1)
    ac.add_address(1, 1)
    ac.add_address(2, 1)
    assert_equal(2, ac.revisions.count)
    assert_equal(3, ac.addresses(nil, false).count)
    assert_equal(6, ac.addresses.count)
    p_img = ac.image
    assert_equal([0x11, 0x22, 0x33], p_img.bytes.to_a[0,3])

    # add revision
    rev = ac.add_revision
    assert_equal(2, ac.current_revision)
    ac.add_address(0, 3)
    assert_equal(3, ac.revisions.count)
    assert_equal(1, ac.addresses(nil, false).count)
    assert_equal(4, ac.addresses.count)

    # test serialization
    h = ac.to_hash
    obj = Bgo::AddressContainer.from_hash h, img
    assert_equal(ac.current_revision, obj.current_revision)
    assert_equal(ac.revisions.count, obj.revisions.count)
    assert_equal(ac.addresses.count, obj.addresses.count)
    assert_equal(ac.addresses(nil, false).count, 
                 obj.addresses(nil, false).count)
  end

end

