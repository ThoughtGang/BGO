#!/usr/bin/env ruby
# :title: Bgo::Debugger
=begin rdoc
Bgo Debugger object

Copyright 2011 Thoughtgang <http://www.thoughtgang.org>

Base class for Debugger objects provided by plugins.
=end

raise "#{__FILE__} : NOT IMPLEMENTED"

module Bgo

=begin rdoc
An object that provides a Debug interface for launching, attaching to, and
controlling a process.

TODO: is a Process object necessary?
=end
  class Debugger

=begin rdoc
Bgo::Process object representing the target.
=end
    attr_reader :process

=begin rdoc
Plugin to use for disassembling instructions.
=end
    attr_accessor :disassembler

=begin rdoc
List of breakpoints
=end
    attr_reader :breakpoints

=begin rdoc
=end
    def initialize(process)
      @process = process
      @breakpoints = []
    end

=begin rdoc
Launch the process under the control of the debugger.
=end
    def launch
      raise NotImplementedError, 'Abstract method'
    end

=begin rdoc
Attach to a running process. Note that this assumes that @process represents 
the process being attached to.
=end
    def attach(pid)
      raise NotImplementedError, 'Abstract method'
    end

=begin rdoc
Terminate the (running) target process.
=end
    def terminate
      raise NotImplementedError, 'Abstract method'
    end

=begin rdoc
Return the current state of the target process.

TODO: State object.
=end
    def state
      raise NotImplementedError, 'Abstract method'
    end

=begin rdoc
Return the contents of a memory location as a binary String.
=end
    def mem_read(vma, length)
      raise NotImplementedError, 'Abstract method'
    end

=begin rdoc
Write a binary String to a memory location.
=end
    def mem_write(vma, buf)
      raise NotImplementedError, 'Abstract method'
    end

=begin rdoc
Return the current value of the specified register.
Note: uses Bgo::Register object
=end
    def reg_read(reg)
      raise NotImplementedError, 'Abstract method'
    end

=begin rdoc
Set the current value of the specified register.
Note: uses Bgo::Register object
=end
    def reg_write(reg, val)
      raise NotImplementedError, 'Abstract method'
    end

=begin rdoc
Execute a single CPU instruction, then stop. Also called single-step or trace.
=end
    def step
      # ss
      raise NotImplementedError, 'Abstract method'
    end

    alias :trace :step
    alias :single_step :step

=begin rdoc
Execute a single CPU instruction. If the instruction performs a call, execute 
the call and stop when the call returns.
=end
    def step_over
      # so
      # TODO: implement with a breakpoint
    end

=begin rdoc
Execute all instructions through the next return instruction, then stop.
=end
    def step_out
      # sr
      # TODO: implement with single-step, looking for return.
    end

    alias :step_return :step_out

=begin rdoc
Continue execution of the target process. This resumes execution after a
breakpoint or a step has stopped the process.
=end
    def continue
      # r
      raise NotImplementedError, 'Abstract method'
    end

    alias :resume :continue

=begin rdoc
Add a breakpoint object.
=end
    def add_breakpoint(bp)
      # apply breakpoint to process
    end

=begin rdoc
Remove a breakpoint object.
=end
    def remove_breakpoint(bp)
      # remove breakpoint
      # todo: how to enable/disable bp
      #       has to be called from Breakpoint object
      #       but needs debugger methods.
    end

=begin rdoc
Perform the specified disassembly task on the target process.
=end
    def disassemble(task, plugin=nil)
    end

  end

=begin rdoc
TODO: breakpoint types. hard, soft (replace with trap), single-step.
actions: log, stop, execute code block
condition (block?)
breakpoint that takes block
=end
  class Breakpoint
    def initialize
      enable
    end

    def enable
      @enabled = true
    end

    def disable
      @enabled = false
    end

    def enabled?
      @enabled
    end
  end

end
