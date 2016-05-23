#!/usr/bin/env ruby
# Standard metadata constants for Instruction objects
# Copyright 2010 Thoughtgang <http://www.thoughtgang.org>

require 'bgo/metadata/register'

module Bgo

  class Instruction
 
    # TODO: side effects
  end

# ----------------------------------------------------------------------
  class Opcode

    # ============================
    # ISA
    
=begin rdoc
General-purpose instructions.
=end
    GEN=:general
=begin rdoc
Graphics card instructions.
=end
    FPU=:fpu
=begin rdoc
Floating-point instructions.
=end
    GPU=:gpu
=begin rdoc
SIMD instructions.
=end
    SIMD=:simd
=begin rdoc
Virtual Machine instructions.
=end
    VM=:vm
=begin rdoc
General privileged (ring0) instructions.
=end
    PRIV=:priv

=begin rdoc
List of all valid ISAs.
=end
    ISA=[GEN, FPU, GPU, SIMD, VM, PRIV]

    # ============================
    # CATEGORY

=begin rdoc
Control flow (jump, call, return) instruction.
=end
    CFLOW=:control_flow
=begin rdoc
Stack manipulation (push, pop) instruction.
=end
    STACK=:stack
=begin rdoc
Load/store (move) instruction.
=end
    LOST=:load_store
=begin rdoc
Test or compare instruction.
=end
    TEST=:test
=begin rdoc
Mathematical (add, sub, mul, etc) instruction.
=end
    MATH=:mathematic
=begin rdoc
Logical (and, or, xor, not, etc) instruction.
=end
    BIT=:bitwise
=begin rdoc
Input/output (i.e. port read/write) instruction.
=end
    IO=:io
=begin rdoc
Trap or interrupt instruction.
=end
    TRAP=:trap
=begin rdoc
Processor/subprocessor/bus control instruction (non-privileged).
=end
    CTL=:control
=begin rdoc
No-operation instruction.
=end
    NOP=:no_op
=begin rdoc
Unknown or unrecognized category
=end
    UNK=:unknown
=begin rdoc
List of all valid instruction categories.
=end
    CATEGORIES=[UNK, CFLOW, STACK, LOST, TEST, MATH, BIT, IO, TRAP, CTL, NOP]

    # ============================
    # OPERATION

=begin rdoc
Call a procedure.
=end
    OP_CALL=:call
=begin rdoc
Conditionally call a procedure.
=end
    OP_CALLCC=:conditional_call
=begin rdoc
Jump to an address.
=end
    OP_JMP=:jump
=begin rdoc
Conditionally jump to an address.
=end
    OP_JMPCC=:conditional_jump
=begin rdoc
Return from a procedure.
=end
    OP_RET=:return
=begin rdoc
Push onto the stack.
=end
    OP_PUSH=:push
=begin rdoc
Pop from the stack.
=end
    OP_POP=:pop
=begin rdoc
Enter a stack frame.
=end
    OP_FRAME=:enter_frame
=begin rdoc
Leave a stack frame.
=end
    OP_UNFRAME=:leave_frame
=begin rdoc
Logical AND operation.
=end
    OP_AND=:bitwise_and
=begin rdoc
Lofical OR operation.
=end
    OP_OR=:bitwise_or
=begin rdoc
Logical XOR operation.
=end
    OP_XOR=:bitwise_xor
=begin rdoc
Logical NOT operation.
=end
    OP_NOT=:bitwise_not
=begin rdoc
=end
    OP_NEG=:bitwise_neg
=begin rdoc
Logical (no carry) shift left.
=end
    OP_LSL=:logical_shift_left
=begin rdoc
Logical (no carry) shift right.
=end
    OP_LSR=:logical_shift_right
=begin rdoc
Arithmetic (with carry) shift left.
=end
    OP_ASL=:arithmetic_shift_left
=begin rdoc
Arithmetic (with carry) shift right.
=end
    OP_ASR=:arithmetic_shift_right
=begin rdoc
Logical (no carry) rotate left.
=end
    OP_ROL=:rotate_left
=begin rdoc
Logical (no carry) rotate right.
=end
    OP_ROR=:rotate_right
=begin rdoc
Arithmetic (with carry) rotate left.
=end
    OP_RCL=:rotate_carry_left
=begin rdoc
Arithmetic (with carry) rotate right.
=end
    OP_RCR=:rotate_carry_right
=begin rdoc
=end
    OP_ADD=:add
=begin rdoc
=end
    OP_SUB=:subtract
=begin rdoc
=end
    OP_MUL=:multiply
=begin rdoc
=end
    OP_DIV=:divide
=begin rdoc
=end
    OP_MIN=:min
=begin rdoc
=end
    OP_MAX=:max
=begin rdoc
=end
    OP_AVG=:average
=begin rdoc
=end
    OP_ABS=:absolute_value
=begin rdoc
=end
    OP_SQRT=:square_root
=begin rdoc
=end
    OP_TRIG=:trigonometric_fn
=begin rdoc
=end
    OP_CONST=:load_constant
=begin rdoc
=end
    OP_FLR=:floor
=begin rdoc
=end
    OP_CEIL=:ceiling
=begin rdoc
=end
    OP_CPUID=:cpuid
=begin rdoc
Read from I/O port.
=end
    OP_IN=:input_from_port
=begin rdoc
Write to I/O port.
=end
    OP_OUT=:output_to_port
=begin rdoc
Unknown operation.
=end
    OP_UNK=:unknown

    # ============================
    # FLAGS

=begin rdoc
Carry flag
=end
    CC_C=:c
=begin rdoc
Zero flag
=end
    CC_Z=:z
=begin rdoc
Overflow flag
=end
    CC_O=:o
=begin rdoc
Direction flag
=end
    CC_D=:d
=begin rdoc
Negative flag
=end
    CC_N=:n
=begin rdoc
Parity flag
=end
    CC_P=:p
=begin rdoc
List of all valid flags
=end
    FLAGS=[ CC_C, CC_Z, CC_O, CC_D, CC_N, CC_P ]

  end

# ----------------------------------------------------------------------
  class Operand

    # ============================
#TODO: address, indirect_address, pc-rel attributes? stored like access.
    # Symbols for each dict element:
    SIZE =  :data_size
    REG =  :register
    IMM_VALUE =  :value
    EXP_DISP =  :displacement 
    EXP_SCALE =  :scale
    EXP_INDEX =  :index
    EXP_BASE =  :base
    EXP_SHIFT =  :shift
    ADDR_SEG =  :segment
    ADDR_OFF_=  :offset
    
    # ============================
    # ACCESS MODES

    ACCESS_R = 'r'
    ACCESS_W = 'w'
    ACCESS_X = 'x'

  end

# ----------------------------------------------------------------------

  class IndirectAddress

    # ============================
    # SHIFT OPERATION

=begin rdoc
Logical (no carry) shift left.
=end
    SHIFT_LSL = :lsl
=begin rdoc
Logical (no carry) shift right.
=end
    SHIFT_LSR = :lsr
=begin rdoc
Arithmetic (carry) shift left.
This is the default.
=end
    SHIFT_ASL = :asl
=begin rdoc
Logical (no carry) rotate right.
=end
    SHIFT_ROR = :ror
=begin rdoc
=end
    SHIFT_RRX = :rrx

  end

end
