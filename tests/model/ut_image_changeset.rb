#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO ImageChangeset class

require 'test/unit'
require 'bgo/image'
require 'bgo/image_changeset'

class TC_ImageChangesetTest < Test::Unit::TestCase

  def test_01_create_revise_patch
    buf = "\x00\x00\x00\x00\xCC\xCC\xCC\xCC\xFF\xFF\xEE\xEE\xDD\xDD\xBB\xBB"
    img = Bgo::Image.new(buf)

    cs = Bgo::ImageChangeset.new img
    assert_equal(0, cs.current_revision)
    assert_equal(img.ident, cs.base_image.ident)
    assert_equal(1, cs.revisions.count)
    # add address
    cs.add_address(0, 0, 1)
    cs.add_address(1, 1, 2)
    cs.add_address(3, 3, 1)
    cs.add_address(4, 4, 4)
    cs.add_address(8, 8, 2)
    assert_equal(5, cs.addresses.values.count)

    # add revision
    rev = cs.add_revision
    assert_equal(1, cs.current_revision)
    assert_equal(2, cs.revisions.count)
    cs.add_address(0, 0, 4)
    cs.add_address(10, 10, 2, 0)
    cs.add_address(12, 12, 2)
    cs.add_address(14, 14, 2)
    assert_equal(3, cs.addresses.values.count)
    assert_equal(6, cs.addresses(0).values.count)
    # remove address
    cs.remove_address(12)
    cs.remove_address(14)
    assert_equal(1, cs.addresses.values.count)
    cs.remove_address(10, 0)
    assert_equal(5, cs.addresses(0).values.count)
    cs.remove_revision(1)
    assert_equal(1, cs.revisions.count)
    assert_equal(0, cs.current_revision)
   
    # add patch
    cs.add_revision
    assert_equal(1, cs.current_revision)
    cs.patch_bytes(0, "\x11\x22\x33")
    cs.add_address(0, 0, 1)
    cs.add_address(1, 1, 1)
    cs.add_address(2, 2, 1)
    assert_equal(2, cs.revisions.count)
    assert_equal(3, cs.addresses.values.count)
    p_img = cs.image
    assert_equal([0x11, 0x22, 0x33], p_img.bytes.to_a[0,3])

    # add revision
    rev = cs.add_revision
    assert_equal(2, cs.current_revision)
    cs.add_address(0, 0, 3)
    assert_equal(3, cs.revisions.count)
    assert_equal(1, cs.addresses.values.count)

    # test serialization
    h = cs.to_hash
    obj = Bgo::ImageChangeset.from_hash h, img
    assert_equal(cs.current_revision, obj.current_revision)
    assert_equal(cs.revisions.count, obj.revisions.count)
    assert_equal(cs.addresses.values.count, obj.addresses.values.count)
  end

end

