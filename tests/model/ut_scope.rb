#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Scope class

require 'test/unit'
require 'bgo/block'
require 'bgo/scope'
require 'bgo/symbol'

class TC_ScopeTest < Test::Unit::TestCase

  def test_1_0_create
    sa = Bgo::Scope.new("A")
    assert(sa.kind_of?(Bgo::Scope), 'Scope not created')
    assert_nil( sa.parent)
    assert_equal( 0, sa.symbols.count )
    sb = Bgo::Scope.new("B", sa)
    assert_equal( sa, sb.parent )
  end

  def test_1_1_symbols
    sx = Bgo::Symbol.new("x", 0)
    sy = Bgo::CodeSymbol.new("y", 0x8040100)
    sz = Bgo::DataSymbol.new("z", "1234567890")

    sa = Bgo::Scope.new("A")
    assert_equal( 0, sa.symbols.count )
    sa.define(sx)
    assert_equal( 1, sa.symbols.count )
    sa.define(sy)
    assert_equal( 2, sa.symbols.count )
    sa.define(sz)
    assert_equal( 3, sa.symbols.count )
  end

  def test_1_2_nesting
    gs = Bgo::Scope.new("GLOBAL")

    gs.define_const('False', 0)
    gs.define_const('True', 1)
    gs.define_const('STDIN', 0)
    gs.define_const('STDOUT', 1)
    gs.define_const('STDERR', 2)
    gs.define_var('errno', 0x80400F0)
    gs.define_func('main', 0x100)
    gs.define_func('cout', 0xE010000, 'stdlib')

    start_addr = 0x8040100
    size = 1024
    b = Bgo::Block.new(start_addr, size)
    b.scope.parent = gs
    b.scope.define_func('main', 0x8040104)
    b.scope.define_var('x', 6)
    b.scope.define_var('errno', 0x8040000)
    b.scope.define_var('y', 7)
    b.scope.define_var('z', 8)

    b1a0 = b.create_child(start_addr + 100, 512)
    b1a0.scope.define_var('errno', 0x8040001)
    b1a0.scope.define_var('x', 66)
    b2a0 = b1a0.create_child(start_addr + 100, 16)
    b2a0.scope.define_var('errno', 0x8040002)
    b2a0.scope.define_var('x', 77)
    b1a1 = b.create_child(start_addr + 128, 256, 1)
    b1a1.scope.define_var('x', 666)
    b1a1.scope.define_var('w', 1.01)

    assert_equal(8, gs.num_symbols)
    assert_equal(0, gs.resolve('False').value)
    assert_equal(0x100, gs.resolve('main').value)
    assert_equal(0x80400F0, gs.resolve('errno').value)
    assert_equal(nil, gs.resolve('cout'))
    assert_equal(0xE010000, gs.resolve('stdlib::cout').value)

    assert_equal(5, b.scope.num_symbols)
    assert_equal(0x8040000, b.scope.resolve('errno').value)
    assert_equal(0x8040104, b.scope.resolve('main').value)
    assert_equal(6, b.scope.resolve('x').value)
    assert_equal(7, b.scope.resolve('y').value)
    assert_equal(8, b.scope.resolve('z').value)

    assert_equal(2, b1a0.scope.num_symbols)
    assert_equal(0x8040001, b1a0.scope.resolve('errno').value)
    assert_equal(0x8040104, b1a0.scope.resolve('main').value)
    assert_equal(66, b1a0.scope.resolve('x').value)
    assert_equal(7, b1a0.scope.resolve('y').value)
    assert_equal(8, b1a0.scope.resolve('z').value)
    assert_equal(nil, b1a0.scope.resolve('w'))

    assert_equal(2, b2a0.scope.num_symbols)
    assert_equal(0x8040002, b2a0.scope.resolve('errno').value)
    assert_equal(0x8040104, b2a0.scope.resolve('main').value)
    assert_equal(77, b2a0.scope.resolve('x').value)
    assert_equal(7, b2a0.scope.resolve('y').value)
    assert_equal(8, b2a0.scope.resolve('z').value)
    assert_equal(0, b2a0.scope.resolve('False').value)
    assert_equal(1, b2a0.scope.resolve('True').value)
    assert_equal(0, b2a0.scope.resolve('STDIN').value)
    assert_equal(1, b2a0.scope.resolve('STDOUT').value)
    assert_equal(2, b2a0.scope.resolve('STDERR').value)
    assert_equal(nil, b2a0.scope.resolve('w'))

    assert_equal(2, b1a1.scope.num_symbols)
    assert_equal(0x8040000, b1a1.scope.resolve('errno').value)
    assert_equal(0x8040104, b1a1.scope.resolve('main').value)
    assert_equal(1.01, b1a1.scope.resolve('w').value)
    assert_equal(666, b1a1.scope.resolve('x').value)
    assert_equal(7, b1a1.scope.resolve('y').value)
    assert_equal(8, b1a1.scope.resolve('z').value)
    assert_equal(0, b1a1.scope.resolve('False').value)
    assert_equal(1, b1a1.scope.resolve('True').value)
    assert_equal(0, b1a1.scope.resolve('STDIN').value)
    assert_equal(1, b1a1.scope.resolve('STDOUT').value)
    assert_equal(2, b1a1.scope.resolve('STDERR').value)
  end


  def test_1_3_modification
  end

  def test_1_4_delete
  end

  def test_1_5_error_handling
=begin
    assert_raises( Bgo::Block::BoundsExceeded ) { 
      b.create_child(start_addr - 1, size) 
    }
    assert_raises( Bgo::Block::BoundsExceeded ) { 
      b.create_child(start_addr, size + 1) 
    }
    assert_raises( Bgo::Block::BoundsExceeded ) { 
      b.create_child(start_addr + 1, size + 1) 
    }
=end
  end

  def test_1_6_serialization
    # TODO: TO JSON
    #       FROM_JSON
  end
end
