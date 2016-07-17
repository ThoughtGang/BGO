#!/usr/bin/env ruby
# :title: Opdis Plugin
=begin rdoc
BGO Opdis ISA plugin

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

A disassembler plugin based on libopcodes.

NOTE: This requires the Opdis gem and libopdis.
https://rubygems.org/gems/Opdis
http://freecode.com/projects/opdis
=end

# TODO: DisasmTasks for BFD symbols, etc.
require 'bgo/application/plugin'

require 'bgo/map'
require 'bgo/section'

require 'rubygems'
require 'Opdis'

module Bgo
  module Plugins
    module Disasm

      class Opdis
        extend Bgo::Plugin

        # ----------------------------------------------------------------------
        # DESCRIPTION

        name 'Opdis'
        author 'dev@thoughtgang.org'
        version '1.0'
        description 'Disassemble bytes with libopdis.'
        help 'Opdis ISA plugin
        Options..
        Etc...
https://rubygems.org/gems/Opdis
https://freecode.com/projects/opdis
        '
        # ----------------------------------------------------------------------
        # SPECIFICATIONS

        spec :disassemble, :disasm, 50 do |task, target|
          # FIXME: check if arch is supported
          next 99 if (task.kind_of? OpdisDisasmTask)
          next 0 if (! task.kind_of? Bgo::LinearDisasmTask) &&
                    (! task.kind_of? Bgo::CflowDisasmTask)
          50
        end

        # ----------------------------------------------------------------------
        # API

        api_doc :disasm, ['DisasmTask', 'Map|Section|Buffer'], 'Hash', \
                          'Perform disassembly task on Target using objdump(1)'

        def disasm(task, target)
          #:options, :arch
          dis = ::Opdis::Disassembler.new
          # TODO: use Opdis cflow strategy to handle BGO cflow strategy
          # decoder : [default decoder for arch]

          buf = target.contents # TODO: revision
          arch = target.arch_info.arch
          syntax = Plugins::Isa::X86::Syntax::ATT
          # TODO: use arch_info to determine disassembler
          task.perform(target) do |image, offset, vma|
            i = dis.disasm_single( buf, :vma => vma, :buffer_vma => 
                                   target.start_addr ).values.first
            # TODO: real decoding instead of to_s, process opdis metadata
            insn = Plugins::Isa::X86::Decoder.instruction(i.to_s, arch, syntax)
            size = i.size
            addr = Address.new( target.image, offset, size, vma, insn )
            target.add_address_object addr
          end

          task.output ? task.output : {}
        end

      end

      # ----------------------------------------------------------------------
      # DISASM_TASK

      class OpdisDisasmTask < Bgo::DisasmTask

        @canon_name = 'Opdis (Control Flow)'
        @sym = :opdis

        #class CustomTracker < Opdis::VisitedAddressTracker
        #  attr_reader :visited_addresses
        #    def initialize()
        #      @visited_addresses = {}
        #    end
        #    def visited?( insn )
        #      return @visited_addresses.fetch(insn.vma, false)
        #    end
        #    def visit( insn )
        #      @visited_addresses[insn.vma] = true
        #    end
        #end

        def cflow?; true; end

        # Opdis.Disassembler.options => opcodes options
        def perform(target, &block)
          # tracker = CustomTracker.new 
          # :arch => 'x86', :insn_decoder => InstructionDecoder
          # :options => libopcodes option string (TODO: method to print this)
          # :syntax => Opdis::Disassembler::SYNTAX_INTEL || SYNTAX_ATT
          # :debug => true, false
          # :resolver => AddressResolver
          # :vma =>
          # :length =>
          # :buffer_vma =>
          #Opdis::Disassembler.new( :addr_tracker => tracker ) do |dis|
          # dis.architectures
          # target is bytes
          #  disasm_cflow( target, args={}, &block )
          #  insns = o.disassemble( t, strategy: o.STRATEGY_CFLOW, start: 0 )
          #  dis.disassemble( bytes ) { |i| puts i }
          #  dis.disasm_entry( tgt ) { |insn|
          #    tracker.visit(insn)
          #  }.values.sort_by{ |i| i.vma }.each { |i| print_insn(i) }
          #end
          # TODO:
          #   * opdis_cflow
          # super target, vma, block

        end
      end

    end
  end
end
