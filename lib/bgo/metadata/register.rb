#!/usr/bin/env ruby
# Standard metadata constants for Register objects
# Copyright 2010 Thoughtgang <http://www.thoughtgang.org>

module Bgo

  class Register

    # ============================
    # TYPE

=begin rdoc
A general-purpose register.
=end
    GEN=:general
=begin rdoc
A floating-point register
=end
    FPU=:fpu
=begin rdoc
A register on the graphics card.
=end
    GPU=:gpu
=begin rdoc
An SIMD register.
=end
    SIMD=:simd
=begin rdoc
A system register for task management
=end
    TASK=:task_mgt
=begin rdoc
A system register for memory management.
=end
    MEM=:memory_mgt
=begin rdoc
A system register for controlling the CPU or bus.
=end
    CTL=:control
=begin rdoc
A system register providing debugger support.
=end
    DBG=:debug
=begin rdoc
The program counter or instruction pointer.
=end
    PC=:pc
=begin rdoc
The flags or condition code register.
=end
    FLAGS=:flags
=begin rdoc
List of all valid register types.
=end
    TYPES = [GEN, FPU, GPU, SIMD, TASK, MEM, DBG, PC, FLAGS]

    # ============================
    # PURPOSE

=begin rdoc
The stack pointer.
=end
    STACK=:stack
=begin rdoc
The frame pointer.
=end
    FRAME=:stack_frame
=begin rdoc
A memory segment register.
=end
    SEG=:segment
=begin rdoc
The (virtual) zero register.
=end
    ZERO=:zero
=begin rdoc
A register used for incoming arguments inside a procedure.
=end
    IN=:in_args
=begin rdoc
A register used for outgoing arguments in a procedure call.
=end
    OUT=:out_args
=begin rdoc
A register used for local variables inside a procedure.
=end
    LOCALS=:locals
=begin rdoc
A register used for a return value from a procedure call
=end
    RET=:return_value
=begin rdoc
A register used as an accumulator.
=end
    ACC=:accumulator
=begin rdoc
A register used as a base index in array operations (x86).
=end
    BASE=:base_index
=begin rdoc
A register used as a counter.
=end
    COUNT=:counter
=begin rdoc
A register used as a source index in a string operation (x86).
=end
    SOURCE=:source_index
=begin rdoc
A register used as a destination index in a string operation (x86).
=end
    DEST=:dest_index

  end

end
