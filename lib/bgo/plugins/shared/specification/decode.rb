#!/usr/bin/env ruby                                                             
# :title: Bgo::Plugin::Specification::DecodeInstruction
=begin rdoc
Specification for Instruction Decoders

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

require 'tg/plugin'

require 'bgo/instruction'

module Bgo
  module Plugin
    module Spec

      # Generate an Instruction object from a string/list of strings (tokens).
      # Input: String (disassembled instruction), String (arch), String (syntax)
      # Output: Instruction
      TG::Plugin::Specification.new( :decode_insn, 'fn(String, String, String)',
                                     [String, String, String],
                                     [Bgo::Instruction]
                                    )
    end
  end
end
