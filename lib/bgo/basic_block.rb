#!/usr/bin/env ruby                                                             
# :title: Bgo::BasicBlock
=begin rdoc
A block of instructions which has no entry or exit points between the start and
end instructions. 

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

module Bgo

=begin rdoc
A sequence of instructions which has no entry or exit points between the start 
and end instructions. The parent of a BasicBlock is always a Block.

Note that a BasicBlock is not a Block object, and is not serialized.
=end
  class BasicBlock
    attr_reader :start_addr
    attr_reader :size
    attr_reader :parent

    def initialize(vma, sz, parent)
      @start_addr = vma || 0
      @size = sz
      @parent = parent
    end

    def ident
      "%08X-%08X" % [@start_addr, (@start_addr + @size)]
    end

    def end_addr
      start_addr + size - 1
    end

    def contains?(vma)
      vma >= start_addr && vma < (start_addr + size)
    end

    def scope; parent.scope; end

    # FIXME : predecessor
    def pred
    end

    # FIXME: successor
    def succ
    end

    def addresses
      parent.container.address_range(start_addr, size, nil, false)
    end

    # ----------------------------------------------------------------------
=begin rdoc
Generate BasicBlocks from Block.
Returns an Array of BasicBlock objects.
=end
    def self.generate(blk)
      # FIXME: generate list of basic blocks
    end
  end
end

