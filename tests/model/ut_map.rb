#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Map class

require 'test/unit'
require 'bgo/map'
require 'bgo/image'

class TC_MapTest < Test::Unit::TestCase

  def test_create
    buf = "\x00\x00\x00\x00\xCC\xCC\xCC\xCC\xFF\xFF\xEE\xEE\xDD\xDD\xBB\xBB"
    
    img = Bgo::Image.new(buf)

    vma, offset, size = 0, 0, 16
    flags = [ Bgo::Map::FLAG_READ, Bgo::Map::FLAG_EXEC]
    ai = Bgo::ArchInfo.new('i386', 'x86-64', Bgo::ArchInfo::ENDIAN_LITTLE)
    m = Bgo::Map.new(vma, img, offset, size, flags, ai)

    assert_equal(vma, m.start_addr)
    assert_equal(offset, m.offset)
    assert_equal(size, m.size)

    img0 = m.image
    assert_equal(buf, img0.contents)

    # Changeset 0 (initial Image): Addr 4@0x4, 2@0x8, 2@0xA, 2@0xE
    m.add_address(0x4, 4)
    assert_equal(1, m.addresses.count)
    m.add_address(0x8, 2)
    assert_equal(2, m.addresses.count)
    m.add_address(0xA, 2)
    assert_equal(3, m.addresses.count)
    m.add_address(0xE, 2)
    assert_equal(4, m.addresses.count)

    assert_raises( Bgo::Map::AddressExists ) { m.add_address(0xD, 3) }
    assert_raises( Bgo::Map::BoundsExceeded ) { m.add_address(0xD, 10) }

    addrs = m.addresses.map{ |a| a.vma }.sort
    assert_equal([4,8,0xA,0xE], addrs)

    # test contiguous address range
    addrs = m.contiguous_addresses.map{ |a| a.vma }.sort
    assert_equal([0,4,8,0xA,0xC,0xE], addrs)
    
    # Changeset 1 : Addr 2@0x0, 2@0x2, 2@0x6, 2@0xA, 2@0xC
    # Address Space : 2@0x0 2@0x2 [2@0x4] 2@0x6 2@0x8 2@0xA 2@0xC 2@0xE
    buf1 = "\x00\x00\x90\x90\xCC\xCC\xC3\xC3\xFF\xFF\xFE\xEE\xDD\xDD\xBB\xBB"
    m.patch_bytes(0x02, "\x90\x90")
    assert_equal(1, m.current_revision)
    assert_equal(2, m.revisions.count)
    m.patch_bytes(0x06, "\xC3\xC3")
    m.patch_bytes(0x0A, "\xFE")
    cs = m.revision
    assert_equal( [2,3,6,7,10], cs.changed_bytes.keys.sort )
    img1 = m.image
    assert_equal(buf1, img1.contents)
    m.add_address(0x0, 2)
    assert_equal(1, m.addresses(false, false).count)
    assert_equal(5, m.addresses.count)
    m.add_address(0x2, 2)
    assert_equal(2, m.addresses(false, false).count)
    assert_equal(6, m.addresses.count)
    m.add_address(0x6, 2)
    assert_equal(3, m.addresses(false, false).count)
    assert_equal(6, m.addresses.count)
    m.add_address(0xA, 2)
    assert_equal(4, m.addresses(false, false).count)
    assert_equal(6, m.addresses.count)
    m.add_address(0xC, 2)
    assert_equal(5, m.addresses(false, false).count)
    assert_equal(7, m.addresses.count)

    addrs = m.addresses.map{ |a| a.vma }.sort
    assert_equal([0,2,6,8,0xA,0xC,0xE], addrs)
    
    # test contiguous address range
    addrs = m.contiguous_addresses.map{ |a| a.vma }.sort
    assert_equal([0,2,4,6,8,0xA,0xC,0xE], addrs)
   
    # Changeset 2 : Addr 4@0x0, 2@0x4, 1@0xB, 1@0xC, 1@0xD
    # Address space: 4@0x0 2@0x4 2@0x6 2X0x8 [1@0xA] 1@0xB 1@0xC 1@0xD 2@0xE
    buf2 = "\xAA\xAA\xAA\xAA\xCC\xCC\xC3\xC3\xFF\xFF\xFE\x00\x00\x00\xBB\xBB"
    m.add_revision
    assert_equal(2, m.current_revision)
    assert_equal(3, m.revisions.count)
    m.patch_bytes(0x00, "\xAA\xAA\xAA\xAA")
    m.patch_bytes(0x0B, "\x00\x00\x00")
    cs = m.revision
    assert_equal( [0,1,2,3,11,12,13], cs.changed_bytes.keys.sort )
    img2 = m.image
    assert_equal(buf2, img2.contents)
    m.add_address(0x0, 4)
    assert_equal(1, m.addresses(false, false).count)
    assert_equal(6, m.addresses.count)
    m.add_address(0x4, 2)
    assert_equal(2, m.addresses(false, false).count)
    assert_equal(7, m.addresses.count)
    m.add_address(0xB, 1)
    assert_equal(3, m.addresses(false, false).count)
    assert_equal(7, m.addresses.count)
    m.add_address(0xC, 1)
    assert_equal(4, m.addresses(false, false).count)
    assert_equal(7, m.addresses.count)
    m.add_address(0xD, 1)
    assert_equal(5, m.addresses(false, false).count)
    assert_equal(8, m.addresses.count)

    addrs = m.addresses.map{ |a| a.vma }.sort
    assert_equal([0,4,6,8,0xB,0xC,0xD,0xE], addrs)

    # test non-strict address range
    addrs = m.address_range( 0x1, 14 ).map {|a| a.vma }.sort
    assert_equal([0,4,6,8,0xB,0xC,0xD,0xE], addrs)

    # test strict address range
    addrs = m.address_range( 0x1, 14, 2, true ).map {|a| a.vma }.sort
    assert_equal([4,6,8,0xB,0xC,0xD], addrs)

    # test contiguous address range
    addrs = m.contiguous_addresses.map{ |a| a.vma }.sort
    assert_equal([0,4,6,8,0xA,0xB,0xC,0xD,0xE], addrs)

    # ensure that previous changesets are still accurate
    # NOTE: arguments are rev, recurse, ident-only
    addrs = m.addresses(0, true, false).map{ |a| a.vma }.sort
    assert_equal([4,8,0xA,0xE], addrs)
    addrs = m.addresses(1, true, false).map{ |a| a.vma }.sort
    assert_equal([0,2,6,8,0xA,0xC,0xE], addrs)
  end

end

