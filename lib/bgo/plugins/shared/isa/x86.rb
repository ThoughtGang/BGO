#!/usr/bin/env ruby
# :title: X86 ISA mixins
=begin rdoc
Intel X86 ISA

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

Code shared by plugins that operate on the Intel x86 ISA.
=end

require 'bgo/isa'

module Bgo
  module Plugins
    module Isa

=begin rdoc
Methods and constants shared by plugins that operate on the Intel x86 ISA.
=end
      module X86
        extend Bgo::Isa
      end

=begin rdoc
Methods and constants shared by plugins that operate on the AMD x86-64 ISA.
=end
      module X86_64
        extend Bgo::Isa
      end

    end
  end
end

require 'bgo/plugins/shared/isa/x86/arch'
require 'bgo/plugins/shared/isa/x86/decoder'
require 'bgo/plugins/shared/isa/x86/metadata'
require 'bgo/plugins/shared/isa/x86/syntax'
