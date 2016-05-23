#!/usr/bin/env ruby
# Utility to generate opcode metadata for x86 instructions.
# Copyright 2010 Thoughtgang <http://www.thoughtgang.org>
# Uses i386-opc.tbl from binutils to generate a complete list of instructions,
# then ia32_opcode.data from libdisasm to generate metadata for as many as 
# possible. The remaining instructions have default ('UNKNOWN') metadata,
# and must be set by hand.

if ARGV.count < 2
  puts "Usage: #{$0} i386-opc.tbl ia32_opcode.data"
  return -1
end

BINUTIL_FILE=ARGV.shift
OPCODE_FILE = ARGV.shift

$instructions = {}

INSN_OP_MAP = {
    'INS_CALL' => ['Bgo::Opcode::CFLOW', 'Bgo::Opcode::OP_CALL'],
    'INS_CALLCC' => ['Bgo::Opcode::CFLOW', 'Bgo::Opcode::OP_CALLCC'],
    'INS_BRANCH' => ['Bgo::Opcode::CFLOW', 'Bgo::Opcode::OP_JMP'],
    'INS_BRANCHCC' => ['Bgo::Opcode::CFLOW', 'Bgo::Opcode::OP_JMPCC'],
    'INS_RET' => ['Bgo::Opcode::CFLOW', 'Bgo::Opcode::OP_RET'],
    'INS_TRET' => ['Bgo::Opcode::CFLOW', 'Bgo::Opcode::OP_RET'],
    'INS_PUSH' => ['Bgo::Opcode::STACK', 'Bgo::Opcode::OP_PUSH'],
    'INS_PUSHREGS' => ['Bgo::Opcode::STACK', 'Bgo::Opcode::OP_PUSH'],
    'INS_PUSHFLAGS' => ['Bgo::Opcode::STACK', 'Bgo::Opcode::OP_PUSH'],
    'INS_POP' => ['Bgo::Opcode::STACK', 'Bgo::Opcode::OP_POP'],
    'INS_POPREGS' => ['Bgo::Opcode::STACK', 'Bgo::Opcode::OP_POP'],
    'INS_POPFLAGS' => ['Bgo::Opcode::STACK', 'Bgo::Opcode::OP_POP'],
    'INS_ENTER' => ['Bgo::Opcode::STACK', 'Bgo::Opcode::OP_FRAME'],
    'INS_LEAVE' => ['Bgo::Opcode::STACK', 'Bgo::Opcode::OP_UNFRAME'],
    'INS_AND' => ['Bgo::Opcode::BIT', 'Bgo::Opcode::OP_AND'],
    'INS_OR' => ['Bgo::Opcode::BIT', 'Bgo::Opcode::OP_OR'],
    'INS_XOR' => ['Bgo::Opcode::BIT', 'Bgo::Opcode::OP_XOR'],
    'INS_NOT' => ['Bgo::Opcode::BIT', 'Bgo::Opcode::OP_NOT'],
    'INS_NEG' => ['Bgo::Opcode::BIT', 'Bgo::Opcode::OP_NEG'],
    'INS_NAN' => ['Bgo::Opcode::BIT', 
                  'Bgo::Opcode::OP_NOT, Bgo::Opcode::OP_AND'], 
    'INS_SHL' => ['Bgo::Opcode::BIT', 'Bgo::Opcode::OP_LSL'],
    'INS_SHR' => ['Bgo::Opcode::BIT', 'Bgo::Opcode::OP_LSR'],
    'INS_SHL' => ['Bgo::Opcode::BIT', 'Bgo::Opcode::OP_ASL'],
    'INS_SHR' => ['Bgo::Opcode::BIT', 'Bgo::Opcode::OP_ASR'],
    'INS_ROL' => ['Bgo::Opcode::BIT', 'Bgo::Opcode::OP_ROL'],
    'INS_ROR' => ['Bgo::Opcode::BIT', 'Bgo::Opcode::OP_ROR'],
    'INS_ROL' => ['Bgo::Opcode::BIT', 'Bgo::Opcode::OP_RCL'],
    'INS_ROR' => ['Bgo::Opcode::BIT', 'Bgo::Opcode::OP_RCR'],
    'INS_ADD' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_ADD'], 
    'INS_INC' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_ADD'],
    'INS_SUB' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_SUB'],
    'INS_DEC' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_SUB'],
    'INS_MUL' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_MUL'],
    'INS_DIV' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_DIV'],
    'INS_MIN' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_MIN'],
    'INS_MAX' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_MAX'],
    'INS_AVG' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_AVG'],
    'INS_FLR' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_FLR'],
    'INS_CEIL' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_CEIL'],
    'INS_CPUID' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_CPUID'],
    'INS_TEST' => ['Bgo::Opcode::TEST', 'Bgo::Opcode::OP_UNK'],
    'INS_CMP' => ['Bgo::Opcode::TEST', 'Bgo::Opcode::OP_UNK'],
    'INS_MOV' => ['Bgo::Opcode::LOST', 'Bgo::Opcode::OP_UNK'],
    'INS_MOVCC' => ['Bgo::Opcode::LOST', 'Bgo::Opcode::OP_UNK'],
    'INS_XCHG' => ['Bgo::Opcode::LOST', 'Bgo::Opcode::OP_UNK'],
    'INS_XCHGCC' => ['Bgo::Opcode::LOST', 'Bgo::Opcode::OP_UNK'],
    'INS_CONV' => ['Bgo::Opcode::LOST', 'Bgo::Opcode::OP_UNK'],
    'INS_STRCMP' => ['Bgo::Opcode::UNK', 'Bgo::Opcode::OP_UNK'],
    'INS_STRLOAD' => ['Bgo::Opcode::LOST', 'Bgo::Opcode::OP_UNK'],
    'INS_STRMOV' => ['Bgo::Opcode::LOST', 'Bgo::Opcode::OP_UNK'],
    'INS_STRSTOR' => ['Bgo::Opcode::LOST', 'Bgo::Opcode::OP_UNK'],
    'INS_XLAT' => ['Bgo::Opcode::UNK', 'Bgo::Opcode::OP_UNK'],
    'INS_BITTEST' => ['Bgo::Opcode::UNK', 'Bgo::Opcode::OP_UNK'],
    'INS_BITSET' => ['Bgo::Opcode::UNK', 'Bgo::Opcode::OP_UNK'],
    'INS_BITCLR' => ['Bgo::Opcode::UNK', 'Bgo::Opcode::OP_UNK'],
    'INS_FMOV' => ['Bgo::Opcode::LOST', 'Bgo::Opcode::OP_UNK'],
    'INS_FMOVCC' => ['Bgo::Opcode::LOST', 'Bgo::Opcode::OP_UNK'],
    'INS_FABS' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_ABS'],
    'INS_FADD' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_ADD'], 
    'INS_FSUB' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_SUB'], 
    'INS_FMUL' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_MUL'], 
    'INS_FDIV' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_DIV'], 
    'INS_FSQRT' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_SQRT'],
    'INS_FCOS' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_TRIG'],
    'INS_FLDPI' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_CONST'],
    'INS_FLDZ' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_CONST'], 
    'INS_FTAN' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_TRIG'], 
    'INS_FSINE' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_TRIG'], 
    'INS_ARITH' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_UNK'], 
    'INS_FPU' => ['Bgo::Opcode::MATH', 'Bgo::Opcode::OP_UNK'], 
    'INS_FCMP' => ['Bgo::Opcode::TEST', 'Bgo::Opcode::OP_UNK'],
    'INS_FSYS' => ['Bgo::Opcode::CTL', 'Bgo::Opcode::OP_UNK'],
    'INS_TRAP' => ['Bgo::Opcode::TRAP', 'Bgo::Opcode::OP_UNK'],
    'INS_TRAPCC' => ['Bgo::Opcode::TRAP', 'Bgo::Opcode::OP_UNK'],
    'INS_BOUNDS' => ['Bgo::Opcode::TRAP', 'Bgo::Opcode::OP_UNK'],
    'INS_DEBUG' => ['Bgo::Opcode::TRAP', 'Bgo::Opcode::OP_UNK'],
    'INS_TRACE' => ['Bgo::Opcode::TRAP', 'Bgo::Opcode::OP_UNK'],
    'INS_INVALIDOP' => ['Bgo::Opcode::TRAP', 'Bgo::Opcode::OP_UNK'],
    'INS_OFLOW' => ['Bgo::Opcode::TRAP', 'Bgo::Opcode::OP_UNK'],
    'INS_HALT' => ['Bgo::Opcode::CTL', 'Bgo::Opcode::OP_UNK'],
    'INS_SYSTEM' => ['Bgo::Opcode::CTL', 'Bgo::Opcode::OP_UNK'],
    'INS_NOP' => ['Bgo::Opcode::NOP', 'Bgo::Opcode::OP_UNK'],
    'INS_IN' => ['Bgo::Opcode::IO', 'Bgo::Opcode::OP_IN'],
    'INS_OUT' => ['Bgo::Opcode::IO', 'Bgo::Opcode::OP_OUT'],
    'INS_OTHER' => ['Bgo::Opcode::UNK', 'Bgo::Opcode::OP_UNK']
}

INSN_FLAG_MAP = {
  'CARRY' => 'Bgo::Opcode::CC_C',
  'ZERO' => 'Bgo::Opcode::CC_Z',
  'OFLOW' => 'Bgo::Opcode::CC_O',
  'DIR' => 'Bgo::Opcode::CC_D',
  'SIGN' => 'Bgo::Opcode::CC_N',
  'PARITY' => 'Bgo::Opcode::CC_P',
  'NCARRY' => 'Bgo::Opcode::CC_C',
  'NZERO' => 'Bgo::Opcode::CC_Z',
  'NOFLOW' => 'Bgo::Opcode::CC_O',
  'NDIR' => 'Bgo::Opcode::CC_D',
  'NSIGN' => 'Bgo::Opcode::CC_N',
  'NPARITY' => 'Bgo::Opcode::CC_P',
  'SFEQOF' => 'Bgo::Opcode::CC_N, Bgo::Opcode::CC_O',
  'SFNEOF' => 'Bgo::Opcode::CC_Z, Bgo::Opcode::CC_O'
}

def get_flags( str, op )
  list = str.split('|').collect{ |x| x.strip }.reject{ |x| x !~ /#{op}/ }
  flags = list.collect{ |x| x.sub("INS_#{op}_",'') }
  if flags.include? 'ALL'
    return [ 'Bgo::Opcode::CC_C', 'Bgo::Opcode::CC_Z', 'Bgo::Opcode::CC_O', 
             'Bgo::Opcode::CC_N', 'Bgo::Opcode::CC_P' ]
  end

  flags.collect{ |x| INSN_FLAG_MAP[x] }.uniq
end

def get_operand_mode( ops )
  mode = [ 0, 0, 0 ]
  ops.each_with_index do |op, idx|
    access = 0
    flags = op.split('|').collect{ |x| x.strip }.reject{ |x| x !~ /OP_[RWX]+/ }
    flags.each do |flg|
      case flg
        when 'OP_X'
          access |= 1
        when 'OP_R'
          access |= 4
        when 'OP_W'
          access |= 2
        when 'OP_RW'
          access |= 6
      end
    end

    mode[idx] = access
  end
  mode
end

def add_insn( mnem, mflg, ops, op_flags, cc )
  $instructions[mnem] ||= {}
  descr = $instructions[mnem]

  return if (descr[:mode] and descr[:mode].length >= op_flags.length)

  cat, ops = INSN_OP_MAP[mflg]
  cat, ops = INSN_OP_MAP['INS_OTHER'] if (not cat) or (not ops)

  descr[:isa] = 'Bgo::Opcode::GEN'
  descr[:category] = cat
  descr[:operations] = ops.split(',')
  descr[:flags_read] = get_flags(cc, 'TEST')
  descr[:flags_set] = get_flags(cc, 'SET')

  descr[:mode] = get_operand_mode(op_flags)
end

File.open(BINUTIL_FILE) do |f|
  f.lines.each do |line|
    next if line.start_with? '//'
    next if line.chomp.empty?
    mnem = line.split(',')[0]
    if not $instructions.include? mnem
      $instructions[mnem] = { :isa => 'Bgo::Opcode::GEN',
                              :category => 'Bgo::Opcode::UNK',
                              :operations => 'Bgo::Opcode::OP_UNK',
                              :flags_read => [], :flags_set => [], :mode => [] }
    end
  end
end

File.open(OPCODE_FILE) do |f|
  f.lines.each do |line|
    next if not line.start_with? 'INSN'
    tbl, mflg, dflg, sflg, aflg, cpu, mnem, dest, src, aux, cc, imp, cmt =
         line.split("\t")
    mnem.gsub!(/"/,'').strip!
    next if mnem.empty?
    # this gets rid of mismatches due to libdisasm suffix
    mnem.chop! if not ($instructions.include? mnem)

    add_insn( mnem, mflg.strip, [dest.strip, src.strip, aux.strip], 
              [dflg.strip, sflg.strip, aflg.strip], cc.strip )
  end
end

puts "#!/usr/bin/env ruby"
puts "# Metadata for x86 opcodes"
puts "# Copyright 2010 Thoughtgang <http://www.thoughtgang.org>"
puts "# Generated by utils/gen_x86_opcode_metadata.rb"
puts "# ----------------------------------------------------------------------"

$instructions.keys.sort.each{|k| puts "'#{k}' => #{$instructions[k].inspect}," }
