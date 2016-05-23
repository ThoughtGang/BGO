#!/usr/bin/env ruby
# :title: Bgo::Trace
=begin rdoc
Bgo Trace object

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>

Classes used for tracing the execution of a Target, Process, or Thread.
=end

raise "#{__FILE__} : NOT IMPLEMENTED"

module Bgo

=begin rdoc
=end
  # TODO: Handle event management? will be overridden by all but ThreadTrace
  class Trace
    attr_reader :timestamp

    def initialize(ts=Time.now)
      @timestamp = ts
    end

    def events
    end
  end

=begin rdoc
=end
  class TargetTrace < Trace
    attr_reader :target
    # all target traces have at least one process
    attr_reader :processes

    # optional members
    attr_accessor :cmd_line
    attr_accessor :hostname
    attr_accessor :user

    def initialization(target, ts=Time.now)
      super ts
      @target = target
      @processes = []
    end

    def events
      # get events for all processes
    end
  end

=begin rdoc
=end
  class ProcessTrace < Trace
    # all process traces have at least one thread
    attr_reader :threads
    attr_reader :symtab
    attr_reader :mmap

    # optional members
    attr_accessor :environment
    attr_accessor :cmd_line
    attr_accessor :pid

    def initialization(tgt_trace, ts=Time.now)
      super ts
      @ttrace = tgt_trace
      @threads = []
      # TODO: memory map = MemoryMap.new
    end

    def events
      # events from all threads
    end
  end

=begin rdoc
=end
  class ThreadTrace < Trace
    attr_reader :start_addr
    # thread-local storage/memory
    # Note: changes to non-thread-local-memory are sent to proc_trace.mmap
    attr_reader :mmap

    # optional members
    attr_accessor :tid

    def initialization(proc_trace, start_addr, ts=Time.now)
      super ts
      @start_addr = start_addr
      @ptrace = proc_trace
    end

    def events
      # use default implementation?
    end
  end

end

