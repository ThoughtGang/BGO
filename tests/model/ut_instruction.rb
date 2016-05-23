#!/usr/bin/env ruby                                                             
# Copyright 2011 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Instruction class

require 'bgo/instruction'
require 'bgo/address'
require 'bgo/image'

require 'fileutils'
require 'test/unit'

class TC_InstructionTest < Test::Unit::TestCase

  def test_isa
    isa_name = 'test-x86-64'

    # test opcode
    opcode = Bgo::Opcode.new('testadd', Bgo::Opcode::GEN, Bgo::Opcode::MATH, 
                 Bgo::Opcode::OP_ADD, [Bgo::Opcode::CC_C], [Bgo::Opcode::CC_Z])
    assert_equal('testadd', opcode.mnemonic)
    assert_equal('testadd', opcode.ascii)
    assert_equal(Bgo::Opcode::GEN, opcode.isa)
    assert_equal(Bgo::Opcode::MATH, opcode.category) 
    assert(opcode.operations.include? Bgo::Opcode::OP_ADD)
    assert(opcode.flags_read.include? Bgo::Opcode::CC_C)
    assert(opcode.flags_set.include? Bgo::Opcode::CC_Z)

    # test register operand
    reg_a = Bgo::Register.new( 'testeax', 1, 0xFFFFFFFF, 4, Bgo::Register::GEN, 
                               Bgo::Register::ACC )
    assert_equal('testeax', reg_a.mnemonic)
    assert_equal('testeax', reg_a.ascii)
    assert_equal(1, reg_a.id)
    assert_equal(0xFFFFFFFF, reg_a.mask)
    assert_equal(4, reg_a.size)
    assert_equal(Bgo::Register::GEN, reg_a.type)
    assert(reg_a.purpose.include? Bgo::Register::ACC)

    reg_ah = Bgo::Register.new( 'testah', 1, 0x0000FF00, 1, Bgo::Register::GEN, 
                               Bgo::Register::ACC )
    assert_equal('testah', reg_ah.mnemonic)
    assert_equal('testah', reg_ah.ascii)
    assert_equal(1, reg_ah.id)
    assert_equal(0x0000FF00, reg_ah.mask)
    assert_equal(1, reg_ah.size)
    assert_equal(Bgo::Register::GEN, reg_ah.type)
    assert(reg_ah.purpose.include? Bgo::Register::ACC)

    assert_equal( 0xFFFFFFFF, reg_a.extract(0xFFFFFFFF) )
    assert_equal( 0x00FFFF00, reg_a.apply(0xFFFFFFFF, 0x00FFFF00) )
    assert_equal( 0xFF, reg_ah.extract(0xFFFFFFFF) )
    assert_equal( 0x0000E100, reg_ah.apply(0x0000FF00, 0xE1) )

    op_reg = Bgo::Operand.new(reg_a.ascii, reg_a)
    assert( op_reg.register? )
    assert( (not op_reg.memory?) )
    assert( (not op_reg.immediate?) )

    reg_c = Bgo::Register.new( 'testecx', 4, 0xFFFFFFFF, 4, Bgo::Register::GEN, 
                               Bgo::Register::COUNT )
    assert_equal('testecx', reg_c.mnemonic)
    assert_equal('testecx', reg_c.ascii)
    assert_equal(4, reg_c.id)
    assert_equal(0xFFFFFFFF, reg_c.mask)
    assert_equal(4, reg_c.size)
    assert_equal(Bgo::Register::GEN, reg_c.type)
    assert(reg_c.purpose.include? Bgo::Register::COUNT)

    # test immediate operand
    op_imm = Bgo::Operand.new("1024", 1024)
    assert( (not op_imm.register?) )
    assert( (not op_imm.memory?) )
    assert( op_imm.immediate? )

    # test indirect address operand
    reg_s = Bgo::Register.new( 'testds', 10, 0xFFFFFFFF, 4, Bgo::Register::GEN, 
                               Bgo::Register::SEG )
    assert_equal('testds', reg_s.mnemonic)
    assert_equal('testds', reg_s.ascii)
    assert_equal(10, reg_s.id)
    assert_equal(0xFFFFFFFF, reg_s.mask)
    assert_equal(4, reg_s.size)
    assert_equal(Bgo::Register::GEN, reg_s.type)
    assert(reg_s.purpose.include? Bgo::Register::SEG)

    addr = Bgo::IndirectAddress.new( 512, reg_a, reg_c, 1, reg_s)
    assert_equal(512, addr.displacement)
    assert_equal(reg_a, addr.base)
    assert_equal(reg_c, addr.index)
    assert_equal(1, addr.scale)
    assert_equal(reg_s, addr.segment)
    assert_equal(Bgo::IndirectAddress::SHIFT_ASL, addr.shift)
    assert( (not addr.fixed?) )

    op_addr = Bgo::Operand.new(addr.to_s, addr)
    assert( (not op_addr.register?) )
    assert( op_addr.memory? )
    assert( (not op_addr.immediate?) )

    # test instruction
    insn = Bgo::Instruction.new(isa_name, 'mov eax, eax', opcode)
    insn.operands << op_reg
    insn.operands << op_addr
    assert_equal(isa_name, insn.arch)

    # test address
    buf = "\x00\x00\x00\x00\xCC\xFF\x90\xCC\xFF\xFF\xEE\xEE\xDD\xDD\xBB\xBB"
    img = Bgo::Image.new(buf)
    a1 = Bgo::Address.new(img, 4, 3)
    a1.contents= insn
    assert_equal( a1.content_type, Bgo::Address::CONTENTS_CODE )
    assert( a1.code? )
    assert( (not a1.data?) )
    cts = a1.contents
    assert( cts.kind_of? Bgo::Instruction )
  end

end
