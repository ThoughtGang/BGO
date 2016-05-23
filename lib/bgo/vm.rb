#!/usr/bin/env ruby
# :title: Bgo::Vm
=begin rdoc
Bgo VM object

Copyright 2010 Thoughtgang <http://www.thoughtgang.org>

NOTES: 
  set_start_state (requires state object)
  can be a vm that single steps execution of a single
  instruction by overwriting %eip.
=end

raise "#{__FILE__} : NOT IMPLEMENTED"

module Bgo

=begin rdoc
An object that mimics a physical machine for the purpose of tracking the
effects of a single instruction on machine state.
This generally entails storing the registers, heap, and stack for a 
process.
=end
  class Vm

=begin rdoc
VmState (or equivalent) representing current state of process.
=end
    attr_accessor :state

=begin rdoc
Valid options:
  :process : A Process object to use. Otherwise a default will be constructed?
=end
    def initialize( options={} )
    end

=begin rdoc
Reset to default StartState
=end
    def reset
      # TODO
    end

=begin rdoc
=end
    def apply( insn )
    end

=begin rdoc
Return Array of the VMAs of instructions that could be executed after this
target, based on the current VM state. The next address in memory, if the
instruction is not a JMP or RET, will always be first.
If an address cannot be resolved, nothing is added to an array... thus
a "ret %eax" in a VM that does not do stack tracking will return an empty array.
NOTE: This invokes resolve(insn.target) if insn.target is not Nil, and if
insn.category is CFLOW.
=end
    def cflow_targets( insn )
      # TODO
    end

=begin rdoc
Return the next address for an instruction, based on flags. This could be
the next address in memory, the target of a jump/call, or the return
address of a call.
NOTE: This does not handle trap instructions.
=end
    def next( insn )
      # TODO
    end

=begin rdoc
Resolve an operand to a VMA using the current VM state (register/stack/mem
contents)
=end
    def resolve( op )
      # TODO
    end

  end

end
