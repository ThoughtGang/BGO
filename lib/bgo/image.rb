#!/usr/bin/env ruby
#:title: Bgo::Image
=begin rdoc
BGO Image object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'digest/sha1'
require 'stringio'
require 'base64'

require 'bgo/model_item'

module Bgo

=begin rdoc
A binary image. This can be the contents of a file, the contents of a location
in memory, or the contents of a patch, and so forth. All binary data is 
stored in an Image object.

This is the base class for Image objects. It also serves as an in-memory
object when there is no backing store.
=end
  class Image 
    extend Bgo::ModelItemClass
    include Bgo::ModelItemObject

=begin rdoc
The ID of the Image, usually the SHA digest of its contents.
=end
    attr_reader :ident
    alias :digest :ident

=begin rdoc
The raw binary data of the Image as a string.
=end
    attr_reader :contents
    alias :content :contents

=begin rdoc
Instantiate an Image from the supplied contents.
=end
    def initialize( contents )
      @ident = Digest::SHA1.hexdigest(contents)
      raise "Image contents must be a String" if (! contents.kind_of? String)
      @contents = contents
      @contents.freeze

      modelitem_init
    end

=begin rdoc
Return a substring of contents.
Same arguments as String#[], except that an index-only argument returns a
String, not a Fixnum.
This means that the following are equivalent:
  :image[0]
  :image[0...1]
  :image[0,1]
=end
    def [](*args)
      # Ensure that result is always a string, not a Fixum (e.g. image[0])
      return contents[args.first,1] if (args.length == 1 && 
                                       args.first.kind_of?(Numeric))
      contents.[](*args)
    end

=begin rdoc
Iterator over bytes in image.
=end
    def bytes
      contents.bytes
    end

=begin rdoc
Return an IO object (usually a StringIO) for the contents of the image.
The caller is expected to close the IO object.
=end
    def io
      StringIO.new(contents)
    end

=begin rdoc
Size of image in bytes.
=end
    def size
      (contents || '').length
    end

=begin rdoc
Return the base (unpatched) Image object for this Image.
This base class method returns self; it is overridden in the PatchedImage class.
=end
    def base_image
      self
    end

=begin rdoc
Return true if image is virtual. Provided for convenience.
=end
    def virtual?
      false
    end

=begin rdoc
Return true if image contents are available for reading. This can only be
false for RemoteImage objects.
=end
    def present?
      true
    end

    # ----------------------------------------------------------------------
    def to_s
      ident
    end

    def inspect
      "Image #{ident}"
    end

    # ----------------------------------------------------------------------
    def to_core_hash
      { :ident => self.ident, :virtual => false }.merge( to_modelitem_hash )
    end

    def to_hash
      to_core_hash.merge( {
        :contents => Base64.encode64(self.contents).gsub("\n", '')
      } )
    end
    alias :to_h :to_hash

    def fill_from_hash(h)
      fill_from_modelitem_hash h
      self
    end

    def self.from_hash(h, proj=nil)
      return nil if (! h) or (h.empty?)
      return RemoteImage.from_hash(h, proj) if h[:remote]
      return VirtualImage.from_hash(h, proj) if h[:virtual]

      obj = self.new( Base64.decode64 h[:contents].to_s )
      obj.fill_from_hash h
    end

  end

=begin rdoc
An Image whose contents lie outside the Project (and the Project repository).
Note: The file must be present when RemoteImage is instantiated, or its size
known.
=end
  class RemoteImage < Image

    def initialize(path, sz=nil, ident=nil)
      @path = path
      if (File.exist? path) && (File.readable? path)
        @present = true
        @contents = File.binread(path)
        sha = Digest::SHA1.hexdigest(@contents)
        raise "RemoteImage source file has changed" if ident and sha != ident
        @ident = sha
      else
        raise "Cannot create a RemoteImage without a size!" if ! sz
        @present = false
        @contents = ([0] * sz)[0,sz].pack('C*')
        @ident = ident
      end
      raise "Invalid RemoteImage '#{ident}'" if (! @ident)

      modelitem_init
    end

    def present?
      @present
    end

    def to_core_hash
      { :ident => ident,
        :virtual => false,
        :remote => true,
        :path => path,
        :size => size
      }.merge( to_modelitem_hash )
    end

    def to_hash
      to_core_hash
    end
    alias :to_h :to_hash

    def self.from_hash(h, proj=nil)
      super
      obj = self.new( h[:path], h[:size].to_i, h[:ident] )
      obj.fill_from_hash h
    end
  end

=begin rdoc
An image that has no actual contents on-disk, e.g. a .bss (zero-initialized)
section. This image consists of a size and a fill value; any contents request
is provided with a buffer of the specified size, initialized to the fill
value.

This is the base class for VirtualImage objects. It also servers as an in-memory
object when there is no backing store.
=end
  class VirtualImage < Image

=begin rdoc
Size of the buffer in bytes
=end
    attr_reader :size
=begin rdoc
Fill pattern used in buffer; generally a single byte.
=end
    attr_reader :fill

=begin rdoc
Format for the ident of a VirtualImage.
=end

    IDENT_FMT = 'virtual(\'%s\',%d)'

    def self.path_elem
      Image.path_elem
    end

    def initialize( fill, size )
      fill = fill[0,size] if (size < fill.length)
      @size = size
      @fill = fill
      fill.freeze
      modelitem_init
    end

    def ident
      fill_hex = fill.bytes.map{ |b| "%02X" % b }.join(' ')
      IDENT_FMT % [fill_hex, self.size]
    end

=begin rdoc
Return true if image is virtual. Provided for convenience.
=end
    def virtual?
      true
    end

=begin rdoc
Return a buffer (String) containing the contents of the Image. This is
actually a string of @size bytes filled with @fill.
=end
    def contents
      pat = fill
      (pat.bytes.collect{|b| b} * ((size/pat.length)+ 1))[0,size].pack('C*')
    end

=begin rdoc
Generate a hexdump for an array of bytes.
This returns an array of Strings of the format "ADDR  HEX  ASCII".

The base_addr argument determines the address of the first byte (default: 0).
The block_size argument determines the number of bytes per line (default: 16).
The delim argument determines the string used to delimit the Address, Hex, and
Ascii sections of the hexdump (default: '  ').

If a block is present, it will be invoked with the arguments addr, hex (the
hex string for the bytes), and asc (the ASCII string for the bytes).
=end
  def self.hexdump(bytes, base_addr=0, block_size=16, delim='  ', &block)
    fmt = "%08X:%c%-#{3 * block_size}s%c%s"
    lines = []
    offset = 0

    bytes.each_slice(block_size) do |line_bytes|
      hex = line_bytes.map { |c| "%02X" % c }.join(' ')
      asc = line_bytes.map { |c| (c < 127 && c > 31) ? c.chr : '.'}.join('')
      addr = base_addr + offset

      lines << (block_given?) ? yield(addr, hex, asc) :
                                fmt % [addr, delim, hex, delim, asc]

      offset += block_size
    end
    lines
  end

=begin rdoc
Generate a hexdump for this Bgo::Image.
This just wraps the generic Bgo::Image.hexdump class method, which can be used
on any array of Integers.
=end
  def hexdump(base_addr=0, block_size=16, delim='  ', &block)
    self.class.hexdump(self.bytes, base_addr, block_size, delim, &block)
  end

=begin rdoc
Return an IO object for the contents of the image.
The caller is expect to close the IO object.
=end
    def io
      StringIO.new(contents)
    end

=begin rdoc
Treat Image as an Array. As with Array, args can be an element, range, etc.

Note: If VirtualImage was created from a String of characters, then it will
be accessed as such ... meaning single-element array access (e.g. img[0])
will return a Fixnum instead of a String (character).
=end
    def [](*args)
      pat = fill
      if args.length == 1 and (args[0].kind_of? Numeric)
        idx = args[0] % pat.length
        pat[idx,1]
      else
        # don't even try, just pass on to contents!
        contents.[](*args)
      end

    end

    # ----------------------------------------------------------------------

    def to_core_hash
      { :ident => self.ident,
        :virtual => true,
        :fill => Base64.encode64(self.fill).gsub("\n", ''),
        :size => self.size,
      }.merge( to_modelitem_hash )
    end

    def to_hash
      to_core_hash
    end
    alias :to_h :to_hash

    def self.from_hash(h, proj=nil)
      obj = self.new( Base64.decode64(h[:fill]).to_s, h[:size].to_i )
      obj.fill_from_hash h
    end

  end

end
