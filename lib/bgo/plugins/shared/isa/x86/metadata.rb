#!/usr/bin/env ruby
# Container for all X86 Metadata
# Copyright 2010 Thoughtgang <http://www.thoughtgang.org>

module Bgo
  module Plugins
    module Isa
      module X86

=begin rdoc
Metadata tables for the x86 architecture.
=end
        module Metadata
        end

      end
    end
  end
end

require 'bgo/plugins/shared/isa/x86/opcode_metadata'
require 'bgo/plugins/shared/isa/x86/register_metadata'
