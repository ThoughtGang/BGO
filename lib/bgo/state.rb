#!/usr/bin/env ruby
# :title: Bgo::State
=begin rdoc
Bgo ProcessState object

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>

Classes used for representing the State of a Process.
=end

raise "#{__FILE__} : NOT IMPLEMENTED"

require 'bgo/image_changeset'

module Bgo

=begin rdoc
The current state of the CPU.
This contains the values of the CPU registers, the current state of the CPU
flags, and the current CPU privilege level.
=end
  class CpuState
 
=begin rdoc
Hash [ Fixnum -> Fixnum ] of CPU register IDs to Fixnum values. This represents
the current value of each CPU register.

Note: see meta-asm for Flag IDs.
=end
    attr_reader :registers
=begin rdoc
Hash [ Fixnum -> Boolean ] of CPU flag IDs to Boolean values. This represents 
the current value of each CPU flag.

Note: see meta-asm for Flag IDs.
=end
    attr_reader :flags
=begin rdoc
Current CPU privilege level.
  -1 : Hypervisor
   0 : Kernel
   3 : Userspace
=end
    attr_reader :ring
    DEFAULT_RING = 3
    # TODO: additional CPU state? product-specific (e.g. Intel MSR)

=begin rdoc
The following keyword arguments are supported:
  :regs : A hash of register IDs to Fixnum values
  :flags : A hash of flag IDs to Boolean values
  :ring : A Fixnum value
=end
    def initialize(args={})
      @registers = args[:regs] || args[:registers] || {}
      @flags = args[:flags] || {}
      @ring = args[:ring] || DEFAULT_RING
    end
  end

=begin rdoc
State of the stack at a point in time.
=end
  class StackState

=begin rdoc
A MapChangeset object representing the changes to bytes on the stack.
=end
    attr_accessor :changeset
    # TODO: stack start, size?

    def initialize(changeset=nil)
      @changeset = changeset || MapChangeset.new(0)
    end
  end

=begin rdoc
State of the heap at a point in time.
=end
  class HeapState
=begin rdoc
A MapChangeset object representing the changes to addresses on the heap.
=end
    attr_accessor :changeset
    # TODO: count, size? num_allocated?

    def initialize(changeset=nil)
      @changeset = changeset || MapChangeset.new(0)
    end
  end

=begin rdoc
The current state of a Process (or a thread within a process). This contains
the current CPU, Stack, and Heap states.

Note that there is no timestamp on a ProcessState; a timestamp is associated
with an Event that contains a ProcessState object.
=end
  class ProcessState
    attr_reader :cpu
    attr_reader :stack
    attr_reader :heap

    def initialize(cpu_state=nil, stack_state=nil, heap_state=nil)
      @cpu = cpu_state || CpuState.new
      @stack = stack_state || StackState.new
      @heap = heap_state || HeapState.new
    end
  end

end
