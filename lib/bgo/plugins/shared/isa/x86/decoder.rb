#!/usr/bin/env ruby
# :title: Bgo::Plugins::Isa::X86::Decoder
=begin rdoc
Decoder for x86 and x86_64 architectures.
Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/instruction'
require 'bgo/plugins/shared/isa/x86/arch'
require 'bgo/plugins/shared/isa/x86/syntax'
require 'bgo/plugins/shared/isa/x86/metadata'

module Bgo
  module Plugins
    module Isa
      module X86

=begin rdoc
Intel x86 and x86-64 asm decoder.
This module is used to generate a BGO Instruction object from an Intel- or
AT&T-syntax assembly language instruction.

Note that Intel syntax is considered 'canonical', while AT&T syntax is
considered an aberration (though it is more convenient for parsing).
=end
        module Decoder

# ----------------------------------------------------------------------
=begin rdoc
AT&T syntax decoding.
References are to binutils source and to the GNU as manual (info page).
=end
          module Att

=begin rdoc
From include/opcode/i386.h in binutils:
  The affected opcode map is dceX, dcfX, deeX, defX.
  See http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=372528
=end
            BUGGY_FPU = %w(fsub fsubr fsubp fsubrp fdiv fdivr fdivp fdivrp)

=begin rdoc
AT&T syntax requires a data size suffix when there is a memory operand. These
are the suffixes with their data size in bytes.
=end
            SUFFIX_SIZES = { 'b' => 1, 'w' => 2, 's' => 2, 'l' => 4, 
                             'q' => 8, 't' => 10 }
=begin rdoc
Long call/jump/return mnemonics. These are the only mnemonics that have prefixes
in the AT&T syntax.
=end
            FAR_CFLOW = [ 'lcall', 'lret', 'ljmp' ]

=begin rdoc
Generate a canonical form of an instruction mnemonic. This handles the 'l'
prefix to far calls and jumps, sign/zero-extens suffixes, and operand size
suffixes.
References are to the GNU as manual (binutis 2.20).
=end
            def self.canonicalize_mnemonic(mnem)
              # From 9.13.3:
              # Immediate form long jumps and calls are 
              # `lcall/ljmp $section, $offset' in AT&T syntax; the Intel 
              # syntax is `call/jmp far section:offset'. Also, the far return 
              # instruction is `lret $stack-adjust' in AT&T syntax; Intel 
              # syntax is `ret far stack-adjust'. 
              return mnem[1..-1] if (FAR_CFLOW.include? mnem)

              # From 9.13.4:
              # Base names for sign extend and zero extend are `movs...' and 
              # `movz...' in AT&T syntax (`movsx' and `movzx' in Intel syntax).
              # The instruction mnemonic suffixes are tacked on to this base 
              # name, the from-suffix before the to-suffix. 
              return mnem[0..3] if mnem =~ /mov[sz][bwlq]+/

              # Handle operand-size suffixes as per 9.13.3
              return mnem.chop if SUFFIX_SIZES.keys.include? mnem[-1,1] 
              
              mnem
            end

=begin rdoc
Returns true if mnemonic is an FPU opcode with backwards operand ordering in
AT&T syntax.

See BUGGY_FPU.
=end
            def self.is_commutative_fpu_op(mnemonic)
              BUGGY_FPU.include? mnemonic
            end

            def data_size_from_insn( insn )
              code = insn.opcode.mnemonic.downcase[-1,1]
              SUFFIX_SIZES[code]
            end

=begin rdoc
AT&T Syntax uses "section, offset" instead of "section:offset" for absolute
address operands to ljmp and lcall. This fixes the problem.
=end
            def self.fix_broken_absaddr( mnemonic, operands )
              # From the GNU as manual, 9.13.3:
              # Immediate form long jumps and calls are 
              # `lcall/ljmp $section, $offset' in AT&T syntax; the Intel 
              # syntax is `call/jmp far section:offset'.

              (mnemonic == 'ljmp' or mnemonic == 'lcall') ? 
                                          operands.sub(/,\s*/, ':') : operands
            end

=begin rdoc
Convert AT&T operand ordering to Intel operand ordering. This ensures that
all x86 Instruction objects have the same operand ordering.
Operands will be re-ordered by an AT&T syntax plugin before being output.
Takes an Instruction object and an array of Operand objects as parameters.
=end
            def self.reorder_operands( insn, operands )
              # Exceptions to operand reordering:

              # 1. From the GNU as manual, 9.13.3:
              #    Note that `bound', `invlpga' ... do not have reversed order
              mnemonic = insn.opcode.mnemonic.downcase
              return if (mnemonic == 'bound') || (mnemonic == 'invlpga')
              
              # 2. From the GNU as manual, 9.13.3:
              #    Note that ... instructions with 2 immediate operands, 
              #    such as the `enter' instruction, do not have reversed order
              num_imm = operands.inject(0){ |sum, op| (op.immediate?) ? 
                                                              sum + 1 : sum }
              return if num_imm > 1

=begin
# TODO: verify if this applies to libopcodes; it may only be for handling
#       input to GNU as as generated by (buggy) GCC.
              
              # 3. From GNU as manual, 9.13.13:
              #    ...all the non-commutative arithmetic floating point 
              #    operations with two register operands where the source 
              #    register is `%st' and the destination register is `%st(i)'.
              return if (is_commutative_fpu_op(mnemonic) and
                      operands[0] and operands[0].mnemonic == '%st' and
                      operands[1] and operands[1].mnemonic =~ /^st\([0-9]+\)$/ )
=end

              # For all other cases, swap the dest and source operands.
              if operands.count > 1
                operands[0], operands[1] = operands[1], operands[0]
              end
            end

=begin rdoc
Return the value of the operand as a Bgo type.
=end
            def self.operand_value( str )

              # extract objdump <> symbols.
              # FIXME: why does this fail? Had to strip in parent.
              if str =~ /^([^<]+)<([^>]*)>/
                str = $1
              end

              # Remove whitespace
              str.strip!

              if str.start_with? '$'
                # AT&T Immediate operands start with $
                return Decoder.immediate(str[1..-1])

              elsif str.start_with? '*'
                # absolute (not PC-rel) jump/call operand
                return indirect_address(str[1..-1])

              elsif str =~ /^%([a-zA-Z0-9]+)$/ or 
                    str =~ /^%([sS][tT]\([0-9]+\))/
                return Decoder.register($1)

              elsif str =~ /^(-)?([[:xdigit:]]+)$/
                # PC-relative address is un-delimited in AT&T.
                return Decoder.immediate( ($1 ? $1 : '') + '0x' + $2)

              end
              
              # Anything else must be an IndirectAddress
              return indirect_address(str)
            end

=begin rdoc
Parse an indirect address (aka effective address aka address expression).
AT&T indirect addresses have the following form:
  segment:displacement(base register, offset register, scalar multiplier)
=end
            def self.indirect_address( str )
              seg = base = index = nil
              scale = 1
              shift = Bgo::IndirectAddress::SHIFT_ASL
              expr = disp = str.dup

              # handle segment:displacement
              if str.include? ':'
                seg, expr = str.split(':')
                disp = expr

                seg = Decoder.register(seg.strip[1..-1]) if seg
              end

              # handle (base, index, scale)
              if expr =~ /^([^(]*)\(([^)]+)\)/
                disp = $1
                base, index, scale = $2.split(',')

                base = Decoder.register( base.strip[1..-1] ) if base
                index = Decoder.register( index.strip[1..-1] ) if index
                scale = scale ? scale.to_i : 1
              end

              # handle single base register (no parentheses)
              if disp and (disp.start_with? '%')
                base = Decoder.register( disp.strip[1..-1] )
                disp = nil
              end

              # get displacement value
              disp = (disp && (not disp.empty?)) ? disp.hex : nil

              Bgo::IndirectAddress.new(disp, base, index, scale, seg, shift)
            end

          end

# ----------------------------------------------------------------------
=begin rdoc
Intel syntax decoding.
=end
          module Intel
=begin rdoc
Parse an indirect address (aka effective address aka address expression).
Intel indirect addresses have the following form:
  seg:[base register + offset register * scalar multiplier + displacement] 
=end
            def self.indirect_address( str )
              seg = base = index = nil
              scale = 1
              shift = Bgo::IndirectAddress::SHIFT_ASL
              expr = disp = str.dup

              # handle segment:displacement
              if str.include? ':'
                seg, expr = str.split(':')
                disp = expr

                seg = Decoder.register(seg.strip) if seg
              end

              # handle [base + index * scale + disp]
              if expr =~ /\s*\[([^\]]+)\]\s/
                expr = $1
              end

              expr.split('+').each do |tok|
                if tok =~ /(0x)?[[:xdigit:]]+/
                  disp = tok
                elsif tok.include? '*'
                  arr = tok.split('*')
                  index = Decoder.register(arr[0].strip)
                  scale = arr[1].to_i
                elsif not base
                  base = Decoder.register(tok.strip)
                else
                  index = Decoder.register(tok.strip)
                end
              end

              disp = (disp && (not disp.empty?)) ? disp.hex : nil

              Bgo::IndirectAddress.new(disp, base, index, scale, seg, shift)
            end

=begin rdoc
Generate BGO object for operand value.
=end
            def self.operand_value( str )
              # extract objdump <> symbols.
              if str =~ /^([^<]+)<([^>]*)>/
                str = $1
              end

              # remove whitespace
              str.strip!

              if str =~ /^[A-Z]+\sPTR\s(.*)$/
                return indirect_address($1)

              elsif str =~ /^(0x)?[[:xdigit:]]+$/
                return Decoder.immediate(str)

              elsif str =~ /^([a-zA-Z0-9]+)$/ or
                    str =~ /^([sS][tT]\([0-9]+\))/
                return Decoder.register($1)
              end

              # Assume anything else is an IndirectAddress
              return indirect_address(str)
            end
          end

# ----------------------------------------------------------------------
# Instruction

=begin rdoc
Guess syntax based on instruction string.
This will default to Intel when the instruction cannot be determined, e.g.
'nop' or 'ret'.

Note: the algorithm used is very crude; it simply checks for the presence of
AT&T-specific characters like %, (, ), $, and *.
=end
          def self.guess_syntax(str)
            syntax = Syntax::INTEL
            syntax = Syntax::ATT if str =~ /[%\(\)\$\*]/
            # TODO: check for AT&T instructions which have no register,
              #     immediate, or IndirectAddress operands: e.g. lret
            syntax
          end

=begin rdoc
Generate an Instruction object for string based on syntax.
          # INTERFACE : BUILD_INSN (object, syntax, arch)
=end
          def self.instruction(str, arch=CANON_ARCH, syntax=nil)
            return nil if (not str) || (str.empty?)
            syntax = guess_syntax(str) if (! syntax) || (syntax.empty?)

            tokens = str.split(' ')
            return nil if tokens.empty?

            prefixes = []
            while is_prefix( tokens.first )
              prefixes << tokens.shift
            end

            mnemonic = tokens.shift
            return nil if not mnemonic

            descr = opcode_descr(mnemonic, syntax)
            opcode = opcode_for_mnemonic(mnemonic, syntax, descr)

            ops = tokens.join(' ')
            ops = Att.fix_broken_absaddr(mnemonic, ops) if syntax == Syntax::ATT

            # get comment if present
            ops_str, cmt = ops.split('#')
            
            # create instruction
            insn = Bgo::Instruction.new(arch, str, opcode, prefixes )
            insn.comment = cmt.strip if cmt
            add_operands( insn, ops_str, syntax, descr )

            # (HUGE) TODO: determine insn effects
            insn
          end

=begin rdoc
Generate Operand objects for str and add them to Instruction.
=end
          def self.add_operands(insn, str, syntax=Syntax::INTEL, descr=nil)
            return nil if (not str) || str.empty?

            ops = operands( str, syntax )

            Att.reorder_operands( insn, ops ) if syntax == Syntax::ATT
            ops.each { |op| insn.operands << op }

            set_operand_access( insn, syntax, descr )
            set_operand_labels( insn )
          end

=begin rdoc
Return true if str is an x86 prefix.
=end
          def self.is_prefix( str )
            return false if not str
            lstr = str.downcase
            (Metadata::PREFIXES.include? lstr) || (lstr.start_with? 'rex.')
          end
  
=begin rdoc
Return the metadata descriptor for an opcode.
=end
          def self.opcode_descr( mnem, syntax )
            descr = Metadata::OPCODES[mnem.downcase]

            if (not descr) && (syntax == Syntax::ATT)
              # Attempt to find instruction after fixing the AT&Tness of it
              old_mnem = mnem.dup
              mnem = Att::canonicalize_mnemonic(mnem)
              descr = Metadata::OPCODES[mnem]
              mnem = old_mnem if not descr
            end

            if not descr
              # Use sane defaults for unknown instructions
              descr = { :isa => Bgo::Opcode::GEN,
                        :category => Bgo::Opcode::UNK,
                        :operations => [ Bgo::Opcode::OP_UNK ],
                        :flags_set => [], :flags_read => [], :mode => [4,2,2]
                      }
              # For debugging:
              #$stderr.puts "NO DESCRIPTOR FOR MNEMONIC '#{mnem}'"
            end

            descr[:mnem] = mnem
            descr
          end

=begin rdoc
Generate an Opcode object for the specified mnemonic.

Note: if descr is non-nil, it will be used instead of performing a lookup.
=end
          def self.opcode_for_mnemonic(mnem, syntax=Syntax::INTEL, descr=nil)
            descr = opcode_descr(mnem, syntax) if not descr

            Bgo::Opcode.new( descr[:mnem], descr[:isa], descr[:category], 
                             descr[:operations], descr[:flags_read], 
                             descr[:flags_set] )
          end

=begin
Set OperandList#access string for all Operands in Instruction object.

Note: if descr is non-nil, it will be used instead of performing a lookup.
=end
          def self.set_operand_access( insn, syntax=Syntax::INTEL, descr=nil )
            descr = opcode_descr(insn.mnemonic, syntax) if not descr

            insn.operands.each_with_index do |op, idx|
              next if idx >= descr[:mode].length
              mode = descr[:mode][idx]
              access = ''
              access << ((mode & 4 > 0) ? Bgo::Operand::ACCESS_R : '-')
              access << ((mode & 2 > 0) ? Bgo::Operand::ACCESS_W : '-')
              access << ((mode & 1 > 0) ? Bgo::Operand::ACCESS_X : '-')
              insn.operands.access[idx] = access
            end
          end

=begin
Set the dest, src, and target Operand label in Instruction.
=end
          def self.set_operand_labels( insn )
            # TODO: make this more intelligent, i.e. use position AND access?
            #       or stick w/ intel syntax?
            operands = insn.operands
            return if operands.length == 0

            # Label the branch target
            operands.target = 0 if insn.branch?

            # In Intel syntax, the first operand is always labelled 'dest'
            insn.operands.dest = 0
            # The second operand is always 'src'
            insn.operands.src = 1 if operands.length > 1
          end

# ----------------------------------------------------------------------
# Operands
 
=begin rdoc
Generate an array of Operand objects from string.
=end
          def self.operands(str, syntax=Syntax::INTEL)
            return [] if (not str) || str.strip.empty?

            # This is a bit tricky; we cannot just split on ',' as 
            # AT&T indirect addresses can contain commas.
            ops = []

            # 1. get list of operand delimiters
            delims = []
            in_paren = false
            idx = 0
            str.each_char do |c|
              in_paren = true if (c == '(')
              in_paren = false if (c == ')')
              delims << idx if (c == ',' && (not in_paren))
              idx +=1
            end

            # 2. extract each (delimited) operand from string, starting 
            #    with the last
            end_idx = str.length
            delims.reverse.each do |i|
              ops << str[i+1...end_idx]
              end_idx = i
            end

            # 3. add the first (undelimited) operand
            ops << str[0...end_idx]

            # 4. create operand objects for each operand str and return array
            ops.reject! { |x| (not x) || x.empty? }
            ops.reverse.collect { |str| operand(str, syntax) }
          end

=begin rdoc
Generate an Operand object based on contents of str.
=end
          def self.operand(str, syntax=Syntax::INTEL)
            return nil if (not str) || (str.empty?)

            val = nil

            case syntax
              when Syntax::ATT
                val = Att::operand_value(str)
              when Syntax::INTEL
                val = Intel::operand_value(str)
            end

            Bgo::Operand.new( str, val )
          end

=begin rdoc
Generate a Register object for the given string (presumed to be a register
name, stripped of any prefixes).

Returns nil if the name is not a recognized register.
=end
          def self.register(name)
            return nil if (not name) || (name.empty?)

            str = name.downcase
            descr = Metadata::REGISTERS[str]

            descr ? Bgo::Register.new( str, descr[:id], descr[:mask], 
                                       descr[:size], descr[:type], 
                                       descr[:purpose] ) : nil
          end

=begin rdoc
Return true if strig is a valid register name.
=end
          def self.register?(str)
            Metadata::REGISTERS.include? str.downcase
          end

=begin rdoc
Generate a Fixnum object for the given string (presumed to represent an 
immediate value, stripped of any prefixes like $ or *).

Assumes decimal unless string is prefixed by 0x or 0X. Assumes positive unless
string is prefixed by -. Note that a negative hexadecimal number has the
prefix -0x or -0X.
=end
          def self.immediate( str )
            return nil if (not str) || (str.empty?)
            (str  =~ /^-?0[xX]/) ? str.hex : str.to_i
          end

=begin rdoc
Generate an IndirectAddress object for the given string.
=end
          def self.indirect_address(str, syntax=Syntax::INTEL)
            return nil if (not str) || (str.empty?)

            case syntax
              when Syntax::ATT
                Att::indirect_address(str)
              when Syntax::INTEL
                Intel::indirect_address(str)
            end
          end

        end

      end
    end
  end
end
