#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO State classes

require 'test/unit'
#require 'bgo/state'
#require 'bgo/changeset'
# NOTE: This is not implemented yet. These tests cases serve as a proposed API.

class TC_StateTest < Test::Unit::TestCase

=begin
  def test_1_cpu_state
    regs = { 1 => 0xFFFF, 2 => 0x0000 }
    flags = { 0 => true, 1 => false }
    ring = 3
    state = Bgo::CpuState.new(:regs => regs, :flags => flags, :ring => ring)
  end

  def test_2_heap_state
    cs = Bgo::MapChangeset.new(0)
    cs.patch_bytes(0x100, [0,0,0,0])
    state = Bgo::StackState.new(cs)
  end

  def test_3_stack_state
    cs = Bgo::MapChangeset.new(0)
    # TODO: generate addresses
    cs.patch_bytes(0x100, [0,0,0,0])
    state = Bgo::HeapState.new(cs)
  end

  def test_4_process_state
    regs = { 1 => 0xFFFF, 2 => 0x0000 }
    flags = { 0 => true, 1 => false }
    ring = 3
    s_cs = Bgo::MapChangeset.new(0)
    s_cs.patch_bytes(0x100, [0,0,0,0])
    h_cs = Bgo::MapChangeset.new(0)
    h_cs.patch_bytes(0x804000, [1,2,3,4])
    state = Bgo::ProcessState.new( Bgo::CpuState.new(:regs => regs, 
                                                     :flags => flags, 
                                                     :ring => ring),
                                   Bgo::StackState.new(s_cs),
                                   Bgo::HeapState.new(h_cs) )

  end
=end
end

