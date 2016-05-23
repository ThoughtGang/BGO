#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO X86Opcodes Plugin
# This tests generation of BGO Instruction objects from x86 ASM strings

require 'test/unit'
require 'bgo/application/plugin_mgr'
require 'bgo/plugins/shared/isa/x86'

class TC_PluginIsaX86Opcodes < Test::Unit::TestCase
  X86 = Bgo::Plugins::Isa::X86::CANON_ARCH
  X86_64 = Bgo::Plugins::Isa::X86_64::CANON_ARCH
  SYN_ATT = Bgo::Plugins::Isa::X86::Syntax::ATT
  SYN_INTEL = Bgo::Plugins::Isa::X86::Syntax::INTEL

  def test_1_requirements
    Bgo::Application::PluginManager.init
    Bgo::Application::PluginManager.startup Bgo::Application.lightweight
  end

  def test_2_guess_syntax
    p = Bgo::Application::PluginManager::find('X86-Opcodes')
    assert_not_nil(p)

    # p.guess_syntax(asm)
  end

  def test_3_decode_x86_att
    p = Bgo::Application::PluginManager::find('X86-Opcodes')
    assert_not_nil(p)
    decode = Proc.new { |asm| p.decode(asm, X86, SYN_ATT) }

    ATT_32.each do |h|
      insn = decode.call(h[:asm])
      assert_not_nil(insn)
      insn_h = insn.to_h
      assert_equal(h[:opcode], insn_h[:opcode])
      assert_equal(h[:operands], insn_h[:operands][:operands])
    end
  end

  def test_4_decode_x86_64_att
    p = Bgo::Application::PluginManager::find('X86-Opcodes')
    assert_not_nil(p)
    decode = Proc.new { |asm| p.decode(asm, X86_64, SYN_ATT) }

    ATT_64.each do |h|
      insn = decode.call(h[:asm])
      assert_not_nil(insn)
      insn_h = insn.to_h
      assert_equal(h[:operands], insn_h[:operands][:operands])
    end
  end

  def test_5_decode_x86_intel
    p = Bgo::Application::PluginManager::find('X86-Opcodes')
    assert_not_nil(p)
    decode = Proc.new { |asm| p.decode(asm, X86, SYN_INTEL) }

    INTEL_32.each do |h|
      insn = decode.call(h[:asm])
      assert_not_nil(insn)
      insn_h = insn.to_h
      assert_equal(h[:operands], insn_h[:operands][:operands])
    end
  end

  def test_6_decode_x86_64_intel
    p = Bgo::Application::PluginManager::find('X86-Opcodes')
    assert_not_nil(p)
    decode = Proc.new { |asm| p.decode(asm, X86_64, SYN_INTEL) }

    INTEL_64.each do |h|
      insn = decode.call(h[:asm])
      assert_not_nil(insn)
      insn_h = insn.to_h
      assert_equal(h[:operands], insn_h[:operands][:operands])
    end
  end

  # ----------------------------------------------------------------------
  # OPCODES FOR TESTING
  # ATT Syntax

  ATT_32 = [
    # Specific operands and opcode/operand combinations
    { :asm => 'sub $0x8, %esp',
      :opcode => { :mnemonic=>"sub", :isa=>:general, :category=>:mathematic, 
                   :operations=>[:subtract], 
                   :flags_tested=>[], 
                   :flags_set=>[:c, :z, :o, :n, :p]},
      :operands => [
        { :ascii => "%esp", :value_type => "Bgo::Register", 
            :value => { :mnemonic => "esp", :id => 5, 
                        :mask => 4294967295, :size=>4, 
                        :type=>:general, :purpose=>[:stack] } }, 
        { :ascii => "$0x8", :value_type => "Fixnum", :value => 8} ] },
    # { :asm => '',
    #   :opcode => {},
    #   :operands => [] },

    # Remaining opcodes: the operands can be missing or invalid
    { :asm => 'nop',
      :opcode => { :mnemonic=>"nop", :isa=>:general, :category=>:no_op, 
                   :operations=>[:unknown], :flags_tested=>[], :flags_set=>[]}, 
      :operands => [] }
  ]
  ATT_64 = [
    # Specific operands and opcode/operand combinations
    { :asm => 'sub $0x8, %rsp',
      :opcode => { :mnemonic=>"sub", :isa=>:general, :category=>:mathematic, 
                   :operations=>[:subtract], 
                   :flags_tested=>[], 
                   :flags_set=>[:c, :z, :o, :n, :p]},
      :operands => [
        { :ascii => "%rsp", :value_type => "Bgo::Register", 
            :value => { :mnemonic => "rsp", :id => 5, 
                        :mask => 18446744073709551615, :size=>8, 
                        :type=>:general, :purpose=>[:stack] } }, 
        { :ascii => "$0x8", :value_type => "Fixnum", :value => 8} ] },
    # { :asm => '',
    #   :opcode => {},
    #   :operands => [] },
    # Remaining opcodes: the operands can be missing or invalid
    { :asm => 'nop',
      :opcode => { :mnemonic=>"nop", :isa=>:general, :category=>:no_op, 
                   :operations=>[:unknown], :flags_tested=>[], :flags_set=>[]}, 
      :operands => [] }
  ]
  # Intel Syntax
  INTEL_32 = [
    # Specific operands and opcode/operand combinations
    { :asm => 'sub esp, 8',
      :opcode => { :mnemonic=>"sub", :isa=>:general, :category=>:mathematic, 
                   :operations=>[:subtract], 
                   :flags_tested=>[], 
                   :flags_set=>[:c, :z, :o, :n, :p]},
      :operands => [
        { :ascii => "esp", :value_type => "Bgo::Register", 
            :value => { :mnemonic => "esp", :id => 5, 
                        :mask => 4294967295, :size=>4,
                        :type=>:general, :purpose=>[:stack] } }, 
        { :ascii => "8", :value_type => "Fixnum", :value => 8} ] },
    # { :asm => '',
    #   :opcode => {},
    #   :operands => [] },
    # Remaining opcodes: the operands can be missing or invalid
    { :asm => 'nop',
      :opcode => { :mnemonic=>"nop", :isa=>:general, :category=>:no_op, 
                   :operations=>[:unknown], :flags_tested=>[], :flags_set=>[]}, 
      :operands => [] }
  ]
  INTEL_64 = [
    # Specific operands and opcode/operand combinations
    { :asm => 'sub rsp, 8',
      :opcode => { :mnemonic=>"sub", :isa=>:general, :category=>:mathematic, 
                   :operations=>[:subtract], 
                   :flags_tested=>[], 
                   :flags_set=>[:c, :z, :o, :n, :p]},
      :operands => [
        { :ascii => "rsp", :value_type => "Bgo::Register", 
            :value => { :mnemonic => "rsp", :id => 5, 
                        :mask => 18446744073709551615, :size=>8, 
                        :type=>:general, :purpose=>[:stack] } }, 
        { :ascii => "8", :value_type => "Fixnum", :value => 8} ] },
    # { :asm => '',
    #   :opcode => {},
    #   :operands => [] },
    # Remaining opcodes: the operands can be missing or invalid
    { :asm => 'nop',
      :opcode => { :mnemonic=>"nop", :isa=>:general, :category=>:no_op, 
                   :operations=>[:unknown], :flags_tested=>[], :flags_set=>[]}, 
      :operands => [] }
  ]
end

