#!/usr/bin/env ruby
# :title: Opcodes Plugin
=begin rdoc
BGO Opcodes disassembler plugin

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

A disassembler plugin based on libopcodes (part of GNU binutils)
=end

require 'tg/plugin'

require 'bgo/file'
require 'bgo/map'
require 'bgo/section'

require 'bgo/disasm'
require 'bgo/address'
require 'bgo/instruction'

require 'Opcodes'

# Require every shared ISA plugin
Dir.foreach( File.dirname(File.dirname(__FILE__)).split(
             File::SEPARATOR)[0..-2].join(File::SEPARATOR) + 
             File::SEPARATOR + 'shared' + File::SEPARATOR + 'isa' ) do |f|
  require "bgo/plugins/shared/isa/#{f}" if (f.end_with? '.rb')
end

# TODO: remove x86 assumptions
module Bgo
  module Plugins
    module Disasm

      class Opcodes
        extend TG::Plugin

        # ----------------------------------------------------------------------
        # DESCRIPTION

        name 'binutils-opcodes'
        author 'dev@thoughtgang.org'
        version '1.0'
        description 'Disassemble insrtructions using libopcodes.'
        help 'libopcodes Disassembler Plugin
Use the GNU binutils libopcodes library to disassemble instructions.
Options:
  :arch    String specifying the CPU architecture (e.g. x86)
  :syntax  Symbol or String specifying the syntax (:att or :intel)
This requires the Opcodes gem from https://rubygems.org/gems/Opdis.'

        # ----------------------------------------------------------------------
        # SPECIFICATIONS

        spec :disassemble, :disasm, 10 do |task, target|
          next 0 if (! task.linear?)
          next 0 if (! target.respond_to? :image)
          # TODO : check if target architecture is supported.
          40
        end

        # ----------------------------------------------------------------------
        # API

        api_doc :disasm, ['DisasmTask', 'AddressContainer'], 'Hash', \
                'Perform disassembly task on Target using libopcodes'
        def disasm(task, target)
          arch = task.options[:arch]
          arch ||= arch_from_target(target)

          # FIXME: make this non-x86 specific. Use Target#arch_info.
          canon_arch = Plugins::Isa::X86_64::canon_arch(arch)

          syntax = task.options[:syntax] ? task.options[:syntax].to_sym : nil
          # FIXME: make this non-x86 specific. Use Target#arch_info.
          syntax ||= Plugins::Isa::X86::Syntax::ATT

          disasm = ::Opcodes::Disassembler.new( :arch => arch )

          task.perform(target) do |image, offset, vma|
            # 1. disassemble address
            # fix this so it works w libopcodes! IO is not handled
            # DO NOT USE IO. A String argument is interpreted as a buffer.
            insn = disasm.disasm_insn( image.contents, :vma => offset )
            # 2. create address object
            addr = address_from_hash( vma, insn, canon_arch, syntax, target )
            # 3. add to Target (note: this will return addr from the block)
            target.add_address_object(addr) if addr
          end

          task.output ? task.output : {}
        end

        api_doc :supported_architectures, [], 'Array', \
                'Return a list of architectures supported by libopcodes.'
        def supported_architectures
          ::Opcodes::Disassembler.architectures
        end


        # ----------------------------------------------------------------------
        def arch_from_target(tgt)
          # TODO: extract from archinfo
          'x86'
        end

        def address_from_hash(vma, h, arch, syntax, target)
          size = h[:size]
          #meta = h[:info]
          asm = h[:insn].join(' ')
          # TODO: extract into create_insn method
          # catch errors
          if asm =~ /<internal disassembler error>/
            # TODO : generate invalid instruction object
            #        using same size as insn?
            return nil
          end

          # Generate Instruction object
          return nil if asm == '(bad)'

          insn = Plugins::Isa::X86::Decoder.instruction(asm, arch, syntax)

          # Create Address object
          offset = target.vma_offset(vma)
          addr = Address.new( target.image, offset, size, vma, insn )
          # TODO: address properties include metadata from libopcodes
          addr
        end


      end

    end
  end
end
