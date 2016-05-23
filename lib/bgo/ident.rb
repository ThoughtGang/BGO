#!/usr/bin/env ruby
# :title: Bgo::Ident

=begin rdoc
Ident object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

This represents the type of a file or buffer (e.g. the libmagic output).
=end

require 'bgo/util/json'

module Bgo

=begin rdoc
Identification of code or data.
TODO: possible file type ala bfd
=end
  class Ident
    extend JsonClass
    include JsonObject

=begin rdoc
File format (e.g. ELF, JPG)
=end
    attr_reader :format
=begin rdoc
Summary of ident info (suitable for display in tooltip)
=end
    attr_reader :summary
=begin rdoc
Full description of file contents
=end
    attr_reader :full
=begin rdoc
Mime-type
=end
    attr_reader :mime
=begin rdoc
Contents are either code or data
=end
    attr_reader :contents
=begin rdoc
Code (executables, object files, code in memory)
=end
    CONTENTS_CODE = :code
=begin rdoc
Data files, data in memory
=end
    CONTENTS_DATA = :data

    CONTENTS = [ CONTENTS_CODE, CONTENTS_DATA ]

=begin rdoc
Unknown/unrecognized file format. Returned by ident plugins when format of
file could not be determined.
=end
    FORMAT_UNKNOWN = 'unknown'
=begin rdoc
Mime-type for unknown/unrecognized file format.
=end
    MIME_UNKNOWN = 'unknown'
=begin rdoc
Mime-type for executable object files.
=end
    MIME_EXECUTABLE = 'application/x-executable'
=begin rdoc
Mime-type for shared library (dynamically-linked) object files.
=end
    MIME_SHAREDLIB = 'application/x-sharedlib'
=begin rdoc
Mime-type for coredump object files.
=end
    MIME_COREDUMP = 'application/x-coredump'
=begin rdoc
Mime-type for object code archive (statically-linked) files.
=end
    MIME_ARCHIVE = 'application/x-archive'
=begin rdoc
Mime-type for object files of unknown type.
This is used when the object file type is unrecognized, or for shellcode.
=end
    MIME_OBJFILE = 'application/x-object'

=begin rdoc
Note: 'mime' and 'format' are only used for files.
Note: ident plugins can leave arch_info as 'nil' in order to force the loader
      to determine it. See ArchInfo note.
=end
    def initialize( contents, summary='', full='', mime=nil, format=nil )
      @contents = contents.to_s.downcase.to_sym
      raise "Invalid contents '#{contents}'" if not CONTENTS.include? @contents
      @summary = summary ? summary : ''
      @full = full ? full : ''
      @mime = mime ? mime : MIME_UNKNOWN
      @format = format ? format : FORMAT_UNKNOWN
    end

    def self.unrecognized
      @unknown ||= Ident.new( CONTENTS_DATA, 'Unrecognized', 
                              'File format could not be determined', nil, 
                              FORMAT_UNKNOWN ).freeze
    end

    def recognized? 
      return (self.format and self.format != FORMAT_UNKNOWN)
    end

    # ----------------------------------------------------------------------
    def to_s
      return (@summary.empty?) ? @contents.to_s: @summary
    end

    def inspect
      "%s|%s|%s|%s\n%s" % [ @contents.to_s, (@mime ||''), (@format || ''), 
                            (@summary || ''), (@full || '') ]
    end

    # ----------------------------------------------------------------------

    def to_hash
      {
        :contents => @contents,
        :mime => @mime,
        :format => @format,
        :summary => @summary,
        :full => @full
      }
    end
    alias :to_h :to_hash

    def self.from_hash(h)
      self.new(h[:contents].to_sym, h[:summary].to_s, h[:full].to_s, 
               h[:mime].to_s, h[:format].to_s)
    end


  end
end
