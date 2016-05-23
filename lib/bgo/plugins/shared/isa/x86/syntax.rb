#!/usr/bin/env ruby
# Standard assembler syntaxes for the x86 architecture.
# Copyright 2010 Thoughtgang <http://www.thoughtgang.org>

module Bgo
  module Plugins
    module Isa
      module X86

        module Syntax
=begin rdoc
AT&T syntax, as defined in the documentation for the GNU assembler (gas).
=end
          ATT = :att
=begin rdoc
Intel syntax, as defined in the Intel documentation.
=end
          INTEL = :intel

          ATT_STRINGS = %w( att at&t as gas opcodes objdump  )
          INTEL_STRINGS = %w( intel masm tasm nasm ida )
        end

=begin rdoc
Return ATT or INTEL if str is a valid name for AT&T or Intel syntax,
respectively. If str is not recognized, nil is returned.
=end
        def self.canon_syntax(str)
          return nil if not str
          name = str.downcase
          return Syntax::ATT if Syntax::ATT_STRINGS.include? name
          return Syntax::INTEL if Syntax::INTEL_STRINGS.include? name
          nil
        end

      end
    end
  end
end
