#!/usr/bin/env ruby
# :title: Bgo::Event
=begin rdoc
Bgo Event object

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>

Classes used for representing events that occur during the tracing of a Thread. 
=end

raise "#{__FILE__} : NOT IMPLEMENTED"

module Bgo

=begin rdoc
=end
  class ThreadEvent
    attr_reader :timestamp

    # optional members
    attr_accessor :tid
    attr_accessor :pid
    attr_accessor :target

    def initialize(ts=Time.now)
      @timestamp = ts
    end
  end

=begin rdoc
A log message emitted during the tracing of a thread.
=end
  class LogThreadEvent < ThreadEvent
    attr_reader :message

    def initialize(message, ts=Time.now)
      super ts
      @message = message
    end
  end

=begin rdoc
Event emitted for a process state change. This can be as fine-grained as a
single instruction step.
=end
  class StateChangeThreadEvent < ThreadEvent
    # ProcessState object
    attr_reader :state

    def initialize(state, ts=Time.now)
      super ts
      @state = state
    end
  end

=begin rdoc
Event emitted for a debugger breakpoint.
=end
  class BreakPointThreadEvent < ThreadEvent
    attr_reader :bp
    alias :breakpoint :bp
    # ProcessState object (optional)
    attr_reader :state

    def initialize(breakpoint, state=nil, ts=Time.now)
      super ts
      @bp = breakpoint
      @state = state
    end
  end

=begin rdoc
Event emitted for a system call.
=end
  class SyscallThreadEvent < ThreadEvent
    # syscall ID, e.g. trap#
    attr_reader :id
    # ProcessState object (optional)
    attr_reader :state
    
    # optional members
    attr_accessor :from_addr
    attr_accessor :args

    def initialize(id, state=nil, ts=Time.now)
      super ts
    end
  end

end
