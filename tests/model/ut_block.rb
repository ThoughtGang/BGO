#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Block class

require 'test/unit'
require 'bgo/block'

class TC_BlockTest < Test::Unit::TestCase

  def test_1_0_create
    start_addr = 0
    size = 100
    b = Bgo::Block.new(start_addr, size)
    assert(b.kind_of?(Bgo::Block), 'Block not created')
    assert(b.scope.kind_of?(Bgo::Scope), 'Scope not created')
    assert_equal(0, b.children.count, 'Children exist on create')
    assert_equal("%08X_%d@0" % [start_addr, size], b.ident)
    assert_equal(start_addr, b.start_addr)
    assert_equal(start_addr + size - 1, b.end_addr)
    assert_equal(size, b.size)
    assert_nil( b.parent)
    assert_equal(0, b.max_revision)
    assert_equal(0, b.nesting)

    b1 = b.create_child(0, 10)
    assert_equal(1, b.children.count)
    assert_equal(1, b.nesting)
    assert(b1.kind_of?(Bgo::Block), 'Block not created')
    assert(b1.parent.kind_of?(Bgo::Block), 'Parent Block invalid')
    assert(b1.scope.kind_of?(Bgo::Scope), 'Scope not created')
    assert(b1.parent.scope.kind_of?(Bgo::Scope), 'Parent Scope invalid')
    assert_equal(0, b1.children.count)
    assert_equal("%08X_%d@0" % [0, 10], b1.ident)
    assert_equal(0, b1.start_addr)
    assert_equal(0 + 10 - 1, b1.end_addr)
    assert_equal(10, b1.size)
    assert_equal(0, b1.max_revision)
    assert_equal(0, b1.nesting)

    b1.create_child(1, 8)
    assert_equal(1, b.children.count)
    assert_equal(1, b1.children.count)
    assert_equal(2, b.nesting)
    assert_equal(1, b1.nesting)
  end

  def test_1_1_revisions
    start_addr = 0x8040100
    size = 1024
    rev = 1
    b = Bgo::Block.new(start_addr, size, nil, rev)
    assert_equal(1, b.max_revision)

    # revision 1
    b.create_child(start_addr + 10, 50)
    b.create_child(start_addr + 60, 100)
    b.create_child(start_addr + 512, 512)
    assert_equal(1, b.max_revision)
    assert_equal(3, b.children.count)
    assert_equal(3, b.map.count)  # uses maximim_revision
    assert_equal(1, b.nesting)

    # revision 2 - replace
    b.create_child(start_addr, 10, 2)
    b.create_child(start_addr + 10, 50, 2)
    b.create_child(start_addr + 60, 100, 2)
    b.create_child(start_addr + 160, 512 - 160, 2)
    assert_equal(2, b.max_revision)
    assert_equal(3, b.children.count)
    assert_equal(4, b.children(2).count)
    assert_equal(1, b.nesting(2))
    assert_equal(4, b.map.count)  # uses maximim_revision

    # revision 3 - overlap
    b.create_child(start_addr + 5, 128, 3)
    b.create_child(start_addr + 200, 256, 3)
    b.create_child(start_addr + 512, 256, 3)
    b.create_child(start_addr + 1000, 16, 3)
    b.create_child(start_addr + 1020, 4, 3)
    assert_equal(3, b.max_revision)
    assert_equal(3, b.children.count)
    assert_equal(4, b.children(2).count)
    assert_equal(5, b.children(3).count)
    assert_equal(5, b.map.count)  # uses maximim_revision
    assert_equal(1, b.nesting(3))

    arr = []
    b.each_revision { |x| arr << x }
    assert_equal(3, arr.count)

    arr = []
    b.each_in_revision(1) { |x| arr << x }
    assert_equal(3, arr.count)
    arr = []
    b.each_in_revision(2) { |x| arr << x }
    assert_equal(4, arr.count)
    arr = []
    b.each_in_revision(3) { |x| arr << x }
    assert_equal(5, arr.count)

    arr = []
    b.each_with_revision { |r, byte| arr << byte }
    assert_equal(12, arr.count)
  end

  def test_1_2_nesting
    start_addr = 0x8040100
    size = 1024
    b = Bgo::Block.new(start_addr, size)
    assert_equal(start_addr, b.start_addr)
    assert_equal(start_addr + size - 1, b.end_addr)
    assert(b.contains?(start_addr + 1))
    assert(b.contains?(start_addr + 512))
    assert(b.contains?(start_addr + 1024 - 1))
    assert(! b.contains?(start_addr - 1))
    assert(! b.contains?(start_addr + 1024))

    # L1 0: [100:612, 612:868] 1: [128:384]
    b1a0 = b.create_child(start_addr + 100, 512)
    b1b0 = b.create_child(start_addr + 100 + 512, 256)
    b1a1 = b.create_child(start_addr + 128, 256, 1)

    # L2 0: [100:16, 116:148, 148:276] 1: [128:256, 256:384]
    b2a0 = b1a0.create_child(start_addr + 100, 16)
    b2b0 = b1a0.create_child(start_addr + 100 + 16, 32)
    b2c0 = b1a0.create_child(start_addr + 100 + 16 + 32, 128)
    b2a1 = b1a1.create_child(start_addr + 128, 128)
    b2b1 = b1a1.create_child(start_addr + 128 + 128, 128)

    # L2 0: [612:740, 740:868] 1: [612:628, 628:660]
    b2d0 = b1b0.create_child(start_addr + 100 + 512, 128)
    b2e0 = b1b0.create_child(start_addr + 100 + 512 + 128, 128)
    b2c1 = b1b0.create_child(start_addr + 100 + 512, 16, 1)
    b2d1 = b1b0.create_child(start_addr + 100 + 512 + 16, 32, 1)

    # L3 0: [104:108, 614:630, 632:696] 1: [612:628]
    b3a0 = b2a0.create_child(start_addr + 100 + 4, 4)
    b3b0 = b2d0.create_child(start_addr + 100 + 512 + 2, 16)
    b3c0 = b2d0.create_child(start_addr + 100 + 512 + 2 + 16, 64)
    b3a1 = b2d0.create_child(start_addr + 100 + 512, 16, 1)

    assert_equal(3, b.nesting)
    assert_equal(2, b1a0.nesting)
    assert_equal(0, b1a0.nesting(1))
    assert_equal(1, b2a0.nesting)

    # kinda silly nesting test
    assert_equal("{{{{}}{}{}}{{{}{}}{}}}", gen_braces(b, 0, '').join(""))
    assert_equal("{  {    {    }  }  {  }  {  }}", gen_braces(b1a0).join(""))
    assert_equal("{  {  }  {  }}", gen_braces(b1a1).join(""))
    assert_equal("{  {    {    }    {    }  }  {  }}",gen_braces(b1b0).join(""))
    assert_equal("{  {  }}", gen_braces(b2a0).join(""))
    assert_equal('{}', gen_braces(b2b0).join(""))
    assert_equal('{}', gen_braces(b2c0).join(""))
    assert_equal("{  {  }  {  }}", gen_braces(b2d0).join(""))
    assert_equal('{}', gen_braces(b2e0).join(""))
    assert_equal('{}', gen_braces(b2a1).join(""))
    assert_equal('{}', gen_braces(b2b1).join(""))
    assert_equal('{}', gen_braces(b2c1).join(""))
    assert_equal('{}', gen_braces(b2d1).join(""))
    assert_equal('{}', gen_braces(b3a0).join(""))
    assert_equal('{}', gen_braces(b3b0).join(""))
    assert_equal('{}', gen_braces(b3c0).join(""))
    assert_equal('{}', gen_braces(b3a1).join(""))

    # To print braces:
    #puts "\n" + gen_braces(b).join("\n")
  end

  def gen_braces(blk, indent=0, delim='  ')
    pad = delim * indent
    arr = blk.children.map { |c| gen_braces(c, indent + 1, delim) }
    arr.unshift(pad + '{')
    arr.push(pad + '}')
    arr
  end

  def test_1_3_modification
    # TODO: nesting, revisions and such
    start_addr = 0x8040100
    size = 1024
    rev = 1
    b = Bgo::Block.new(start_addr, size, nil, rev)

    b1 = b.create_child(start_addr + 10, 50)
    b.create_child(start_addr + 60, 100)
    b.create_child(start_addr + 512, 512)

    assert_raises( Bgo::Block::BoundsExceeded ) { b1.start_addr = 0x80400FF }
    assert_raises( Bgo::Block::BoundsExceeded ) { b1.start_addr = 0x08040500 }
    assert_raises( Bgo::Block::BoundsExceeded ) { b1.size = 1025 }
    assert_raises( Bgo::Block::ChildOverlap ) { b1.start_addr = 0x08040132 }
    assert_raises( Bgo::Block::ChildOverlap ) { b1.size = 60 }

    b1.start_addr = start_addr
    assert_raises( Bgo::Block::Duplicate ) { b1.size = 1024 }
    assert_equal(b1.start_addr, start_addr)
    assert_equal(b1.end_addr, start_addr + 50 - 1)
    b1.size = 60
    assert_equal(b1.end_addr, start_addr + 60 - 1)
  end

  def test_1_4_delete
    # TODO: nesting, revisions and such
    start_addr = 0x8040100
    size = 1024
    rev = 1
    b = Bgo::Block.new(start_addr, size, nil, rev)
    b.create_child(start_addr + 10, 50)
    b.create_child(start_addr + 60, 100)
    b.create_child(start_addr + 512, 512)
    assert_equal(3, b.num_children)

    b.delete(start_addr + 60)
    assert_equal(2, b.num_children)
    b.delete(start_addr + 50)
    assert_equal(1, b.num_children)

    b.create_child(start_addr + 10, 50)
    b.create_child(start_addr + 60, 100)
    assert_equal(3, b.num_children)
    b.clear
    assert_equal(0, b.num_children)
    assert(! b.has_children?)
  end

  def test_1_5_error_handling
    start_addr = 0x8040100
    size = 1024
    b = Bgo::Block.new(start_addr, size, nil, 2)
    assert_raises( Bgo::Block::Duplicate ) { b.create_child(start_addr, size) }
    assert_raises( Bgo::Block::BoundsExceeded ) { 
      b.create_child(start_addr - 1, size) 
    }
    assert_raises( Bgo::Block::BoundsExceeded ) { 
      b.create_child(start_addr, size + 1) 
    }
    assert_raises( Bgo::Block::BoundsExceeded ) { 
      b.create_child(start_addr + 1, size + 1) 
    }


    b.create_child(start_addr + 256, 512)
    assert_raises( Bgo::Block::ChildOverlap ) { 
      b.create_child(start_addr, 1000) 
    }
    assert_raises( Bgo::Block::ChildOverlap ) { 
      b.create_child(start_addr + 128, 512) 
    }
    assert_raises( Bgo::Block::ChildOverlap ) { 
      b.create_child(start_addr + 512, 512) 
    }
    assert_raises( Bgo::Block::ChildOverlap ) { 
      b.create_child(start_addr + 384, 64) 
    }
  end

  def test_1_6_basic_blocks
    # block-gen
    # * foreach address in block
    # *   if [insn-type] end bblock
    # *   if [! insn] end bblock
    # * cached
    # custom block-gen method
    # children
    # * cached
    # revision
    # graph from basic blocks [see how metasm handles this]
  end

  def test_1_7_serialization
    # TODO: TO JSON
    #       FROM_JSON
  end

  def generate_block_with_insns
    # fill block with addresses and instructions
  end

  def generate_nested_blocks_with_insns
  end

  def generate_block_revisions_with_insns
  end
end
