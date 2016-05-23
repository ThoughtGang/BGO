#!/usr/bin/env ruby
# Architecture constants for x86 and x86-64
# Copyright 2010 Thoughtgang <http://www.thoughtgang.org>

module Bgo
  module Plugins
    module Isa

      module X86

        ARCH_STRINGS = %w( x86 i386 80386 ia32 ia-32 ia_32 )

        CANON_ARCH = :x86

=begin rdoc
Return true if argument describes an x86 ISA, i.e. it is one of
        x86 i386 80386 ia32 ia-32 ia_32
=end
        def self.include?(str)
          ARCH_STRINGS.include? str.downcase
        end

=begin rdoc
Return CANON_ARCH if str is a recognized x86 ISA, nil otherwise.
=end
        def self.canon_arch(str)
          str && (include? str) ? CANON_ARCH : nil
        end

      end

=begin rdoc
Constants for the x86-64 (nee AMD64) ISA.
=end
      module X86_64

        ARCH_STRINGS = %w( x86-64 x86_64 amd64 )

        CANON_ARCH = :x86_64

=begin rdoc
Return true if argument describes an x86-64 ISA, i.e. it is one of
        x86-64 x86_64 amd64
=end
        def self.include?( str )
          ARCH_STRINGS.include? str.downcase
        end

=begin rdoc
Return CANON_ARCH if str is a recognized x86-64 ISA, nil otherwise.
=end
        def self.canon_arch(str)
          str && include?(str) ? CANON_ARCH : nil
        end

      end

    end
  end
end
