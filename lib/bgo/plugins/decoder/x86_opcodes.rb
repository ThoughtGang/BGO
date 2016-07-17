#!/usr/bin/env ruby
# :title: X86Opcodes Plugin
=begin rdoc
BGO X86Opcodes ISA plugin

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

An instruction decoder plugin.

Assumes the instructions have been disassembled by libopcodes, i.e. a string 
in AT&T or Intel syntax.
=end

require 'bgo/application/plugin'
require 'bgo/instruction'
require 'bgo/plugins/shared/isa/x86'

module Bgo
  module Plugins
    module Decoder

      class X86Opcodes
        extend Bgo::Plugin

        # ----------------------------------------------------------------------
        # DESCRIPTION
        
        name 'X86-Opcodes'
        author 'dev@thoughtgang.org'
        version '1.1'
        description 'Generate BGO Instruction objects from a libopcodes-style disassembly.'
        help 'x86-Opcodes ISA plugin
        Provides conversion of libopcodes (part of GNU binutils) output to BGO
        instruction objects. This can be used to generate BGO instructions for
        any disassembly that matches libopcodes syntax and has the following
        format:
           mnemonic operands
        Note: no addresses or hex bytes can be included in the line, and all 
              tokens must be space-separated.
        
    Interfaces
        IFACE_DECODE |asm, arch, syntax|
          "asm" can be an empty String during interface query.
          This interface simply calls the decode_insn() API method.

    API
        decode_insn(asm, arch, syntax)
          Create a BGO Instruction object for the ASCII instruction in "asm".
          "asm" must be an ASCII String. It can be empty during query.
          "arch" is a String specifying a valid x86 architecture name.
          If "arch" is "", "x86-64" will be used.
          "syntax" is a String specifying a valid x86 syntax name.
          If "syntax" is "", guess_syntax() will be called.

        guess_syntax(asm)
          Guess the syntax ("intel" or "att") of an assembly language instruction.
        '

        # ----------------------------------------------------------------------
        # SPECIFICATIONS
        spec :decode_insn, :decode, 75 do |asm, arch, syntax|
          # Note: asm, arch, and syntax are guaranteed to be String objects
          confidence = 0

          c_arch = Plugins::Isa::X86::canon_arch(arch)
          c_arch ||= Plugins::Isa::X86_64::canon_arch(arch)
          confidence += 25 if c_arch
          c_syn = Plugins::Isa::X86::canon_syntax(syntax)
          confidence += 25 if c_syn

          # Default to x86_64 when arch and syntax are not specified
          c_arch = Plugins::Isa::X86_64::canon_arch('x86-64') if (arch.empty?)
          c_syn = '' if (syntax.empty?)

          if c_arch && c_syn
            insn = Plugins::Isa::X86::Decoder.instruction(asm, c_arch, c_syn)

            confidence += 25 if insn
            confidence += 25 if (insn && insn.opcode.category != :unknown)
            # TODO: more detailed analysis, e.g. operand count?
          end

          confidence
        end

        # ----------------------------------------------------------------------
        # API

        api_doc :decode, ['String asm', 'String arch', 'String syntax'], \
                'Instruction', 'Decode disassembled instruction'
        def decode(asm, arch, syntax)
          arch = 'x86-64' if not arch
          return nil if not asm.kind_of?(String) 

          c_arch = Plugins::Isa::X86::canon_arch(arch)
          c_arch ||= Plugins::Isa::X86_64::canon_arch(arch)
          c_arch ||= Plugins::Isa::X86_64::canon_arch('x86-64') if (arch.empty?)

          c_syn = Plugins::Isa::X86::canon_syntax(syntax)
          c_syn ||= ''

          Plugins::Isa::X86::Decoder.instruction(asm, c_arch, c_syn)
        end

        api_doc :guess_syntax, ['String asm'], 'String', \
                'Guess the syntax of an asm instruction'
        def guess_syntax(asm)
          Plugins::Isa::X86::Decoder.guess_syntax(asm).to_s
        end

      end

    end
  end
end
