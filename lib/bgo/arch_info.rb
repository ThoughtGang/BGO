#!/usr/bin/env ruby
# :title: Bgo::ArchInfo

=begin rdoc
ArchInfo object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/util/json'

module Bgo

=begin rdoc
Architecture information for a file. This is inspired by the BFD arch/mach
model.
NOTE: Most ident plugins (e.g. file, magic) provide irregular strings that
cannot be reliably used for determining Architecture Info for a target. Such
plugins should set the ArchInfo member to nil, so that a Loader plugin can
fill in the missing information.
=end
  class ArchInfo
    extend JsonClass
    include JsonObject

=begin rdoc
A String representing the CPU architecture.

Note: Strings are determined by plugins; there is no real standardization.
=end
    attr_reader :arch

=begin rdoc
A String representing the specific model or revision, ala BFD.
=end
    attr_reader :mach

=begin rdoc
Unknown arch or mach string.
=end
    UNKNOWN = 'unknown'

=begin rdoc
A Symbol representing the architecture byte order (little, big).
=end
    attr_reader :endian

=begin rdoc
Little-endian (e.g. Intel)
=end
    ENDIAN_LITTLE = :little
=begin rdoc
Big-endian (e.g. SPARC, PPC)
=end
    ENDIAN_BIG = :big

    def initialize( arch, mach, endian )
      @arch = arch.to_s.downcase
      @mach ||= UNKNOWN
      @mach = mach.to_s.downcase
      @endian = endian.to_s.downcase.to_sym

      raise "Invalid endian symbol '#{endian.inspect}'" if  \
            (@endian != ENDIAN_LITTLE and @endian != ENDIAN_BIG) 
    end

    # ----------------------------------------------------------------------
    def to_s
      "#{@arch}: #{@mach} (#{@endian.to_s} endian)"
    end

    def inspect
      "%s,%s,%s" % [@arch, @mach, @endian.inspect]
    end

    def to_hash
      {
        :arch => @arch,
        :mach => @mach,
        :endian => @endian.to_s,
      }
    end
    alias :to_h :to_hash

    
    def self.from_hash(h)
      self.new(h[:arch].to_s, h[:mach].to_s, h[:endian].to_sym)
    end

    # ----------------------------------------------------------------------
    def self.unknown
      new( UNKNOWN, UNKNOWN, ENDIAN_LITTLE )
    end

  end

=begin rdoc
Network Architecture: a convenience class providing an ArchInfo for packets.
=end
  class NetworkArchInfo < ArchInfo
    ARCH = 'network'
    def initialize(type=ArchInfo::UNKNOWN)
      super ARCH, type, ENDIAN_BIG
    end
  end

end
