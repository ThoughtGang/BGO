#!/usr/bin/env ruby                                                             
# :title: Bgo::Plugin::Specification::Disassemble
=begin rdoc
Specification for disassembler plugins

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'tg/plugin'

require 'bgo/disasm'
require 'bgo/address_container'

module Bgo
  module Plugin
    module Spec

      # Disassemble the target, creating Address and Instruction operands for 
      # each instruction. This will add Address objects to the AddressContainer
      # via AddressContainer#add_address_object().
      # Input: Bgo::DisasmTask, Bgo::AddressContainer
      # Output: Hash of disassembled addresses (from DisasmTask#output)
      # FIXME: there is no need to return the output of the DisasmTask
      TG::Plugin::Specification.new( :disassemble, 
                                    'fn(DisasmTask, AddressContainer)',
                                     [Bgo::DisasmTask, Bgo::AddressContainer], 
                                     [Hash]
                                    )
      # TODO: specification for returning a custom DisasmTask object
      #       (e.g. for emulation)
    end
  end
end
