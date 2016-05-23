#!/usr/bin/env ruby
# :title: Bgo::Git::Instruction
=begin rdoc
BGO Instruction object in Git-DB

Copyright 2010 Thoughtgang <http://www.thoughtgang.org>
=end

# NOTE: THIS IS OBSOLETE. It may be used to re-implement singleton
#       Instruction Descriptions, though.
__END__


require 'bgo/instruction'

require 'rubygems'
require 'git-ds/model'
require 'bgo/git/shared'

require 'bgo/git/isa'

module Bgo
  module Git

    # TODO: ISA Register cache? Prob save a ton of space.
    
=begin rdoc
The instruction cache saves a copy of each Bgo::Git::Instruction, indexed by 
ISA (Bgo::Instruction#arch) and bytestring. This reduces disk access during 
address instantiation and disassembly.
=end
    class InstructionCache
      @enabled = true
      @isa_cache = {}

=begin rdoc
Enable caching of Bgo::Git::Instruction objects. This is on by default.
=end
      def self.enable
        @enabled = true
      end

=begin rdoc
Disable caching of Bgo::Git::Instruction objects. This should only be used for
debugging.
=end
      def self.disable
        @enabled = false
      end

=begin rdoc
Add a Bgo::Git::Instruction object to the cache.

'arch' is the name of the Bgo::Git::Isa object containing the Instruction.

NOTE: this freezes all objects owned by the Bgo::Git::Instruction.
=end
      def self.add(arch, ident, insn)
        return if not @enabled

        insn.opcode.freeze
        insn.operands.each { |op| op.freeze }
        insn.operands.freeze

        @isa_cache[arch] ||= {}
        @isa_cache[arch][ident] = insn
      end

=begin rdoc
Fetch a cached Bgo::Git::Instruction or return nil
=end
      def self.fetch(arch, ident)
        @enabled && @isa_cache[arch] ? @isa_cache[arch][ident] : nil
      end

=begin rdoc
Remove a Bgo::Git::Instruction from the cache
=end
      def self.remove(arch, ident)
        @isa_cache[arch].delete(ident) if @isa_cache[arch]
      end

=begin rdoc
Clear instruction cache for architecture. If no archtitecture is specified, the
entire cache is cleared.
=end
      def self.clear(arch=nil)
        arch ? (@isa_cache[arch].clear if @isa_cache[arch]) : @isa_cache.clear
      end

    end

    # =======================================================================
=begin rdoc
A BGO Instruction object stored in the project repo.

An Instruction represents a unique combination of Prefixes, an Opcode, and
a list of Operands. Each distinct Instruction is only stored once in the 
Database; it is expected that multiple Address objects will link to a
single in-Database Instruction object. This provides extensive storage savings
as the expense of data model complexity.

Instruction objects are grouped by architecture, with the bytes that make
up the instruction serving as the UID for the instruction on that 
architecture. An architecture is actually an ISA (instruction set 
architecture); it is possible to have semi-redundant architectures such
as x86 and x86-64, resulting in multiple copies of an Instruction object
across architectures.

This Instruction class wraps the ISA definitions. See Git::Isa for the 
internals of instruction storage.
=end
    class Instruction < Bgo::Instruction

=begin rdoc
Ident member to make this act like a ModelItem.
=end
      attr_accessor :ident

=begin rdoc
Construct a Bgo::Git::Instruction object.

'arch' is a String containing the name of the ISA for the instruction. This 
can be obtained from Bgo::Instruction#arch.

'bytestring' is a String containing the raw (binary) bytes that encode the
instruction. This can be obtained from Bgo::Address#bytes.
=end
      def self.factory(model, arch, bytestring)
        isa = Isa.factory(model, arch)

        # instructions are keyed by bytestring
        ident = bytestring.bytes.collect{ |x| "%02X" % x }.join

        Instruction.new(isa, ident)
      end

=begin rdoc
Instantiate an Instruction object from the data model for the given ident. If
the Bgo::Git::InstructionCache is enabled (it is by default), then an existing
Instruction object is returned from the cache if one exists. These objects
are frozen and cannot be modified.

See Bgo::Git::Instruction#initialize for parameters.
=end
      def self.new(parent, ident)
        insn = InstructionCache.fetch(parent.ident, ident)
        insn ? insn : super(parent, ident)
      end

=begin rdoc
Instantiate an Instruction object from the data model for the given ident.

Note: 'parent' is a Bgo::Git::Isa object containing the instruction. 'ident' is
a hex representation of the bytes encoding the instruction; this can be
obtained via Bgo::Address#bytes.bytes.collect{|x| "%02X" % x }.join .
=end
      def initialize(parent, ident)
        @ident = ident

        arch = parent.ident
        insn = parent.instruction(ident)

        op = insn.opcode
        opcode = Bgo::Opcode.new( op.ident, op.isa, op.category, op.operations, 
                                  op.flags_read, op.flags_set )

        super arch, insn.ascii, opcode, insn.prefixes, insn.side_effects

        comment = insn.comment

        build_operand_list(insn)

        InstructionCache.add(arch, ident, self)
      end

=begin rdoc
Create a new Instruction object in the repo. This returns the IsaInstruction 
(ISA instruction definition object) for the instruction.

'insn' is a Bgo::Instruction object.
=end
      def self.from_obj(model, insn, bytestring)
        isa = Isa.factory(model, insn.arch)
        ident = bytestring.bytes.collect{ |x| "%02X" % x }.join

        # if exists in cache, do not create
        obj = InstructionCache.fetch(isa.ident, ident)
        return obj if obj

        isa.add_instruction(insn, bytestring)
      end

=begin rdoc
Create a new Instruction object in the repo. This returns the arch string
and the ident for the Instruction object (i.e. an Array [arch,ident] ).

'insn' is a Bgo::Instruction object.

'bytestring' is a String containing the raw (binary) bytes that encode the
instruction. These are used as a primary key; it stands to reason that every 
unique combination of bytes under a CPU architecture maps to a unique 
instruction. This parameter can be obtained from Bgo::Address#bytes.

NOTE: Unlike the other Model objects, Instruction can only be created from
a Bgo::Instruction object (due to the complexity of its implementation).
This means that create accepts a Bgo::Instruction object, as if it were 
from_obj.
=end
      def self.create(model, insn, bytestring)
        isa_insn = from_obj(model, insn, bytestring)
        [insn.arch, isa_insn.ident]
      end

      protected

=begin rdoc
Fill the Bgo::OperandList for the Bgo::Instruction being initialized.

Note: This relies heavily on IsaInstruction for handling operand order and
operand access.
=end
      def build_operand_list(insn)
        op_access = insn.operand_access
        op_order = insn.operand_order
        ops = Array.new(op_order.count)

        insn.operands.each do |op_ident|
          idx = op_order.index(op_ident)

          op_def = insn.operand(op_ident)
          val = value_factory(op_def)

          self.operands.dest = idx if insn.dest == op_def
          self.operands.src = idx if insn.src == op_def
          self.operands.target = idx if insn.target == op_def

          op = Bgo::Operand.new(op_ident, val, op_access[idx])
          ops[idx] = op
        end

        ops.each { |op| operands << op }
      end

=begin rdoc
Instantiate a Bgo::Operand#value based the contents of a Bgo::Git::IsaOperand
object.

This returns a Bgo::Registers, Bgo::IndirectAddress, or Fixnum (immediate).
=end
      def value_factory(op)
        case op.type
          when IsaOperand::REG
            # return Register object
            reg_factory(op.register)
          when IsaOperand::IND
            # return IndirectAddress object
            Bgo::IndirectAddress.new(op.displacement,
                                     reg_factory(op.base),
                                     reg_factory(op.index), op.scale,
                                     reg_factory(op.segment), op.shift)
          when IsaOperand::IMM
            # return Fixnum object
            op.value
        end
      end

=begin rdoc
Instantiate a Bgo::Register object from a Bgo::Git::IsaRegister object.
=end
      def reg_factory(reg)
        return nil if not reg
        Bgo::Register.new(reg.ident, reg.id, reg.mask, reg.size, reg.type, 
                          reg.purpose)
      end

      def inspect
        "#{path}: #{super}"
      end

    end

  end
end
