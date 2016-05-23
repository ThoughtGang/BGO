#!/usr/bin/env ruby
# :title: Bgo::Address
=begin rdoc
BGO Address object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

An address can contain structured data, an instruction, or raw bytes.
=end

require 'bgo/image'
require 'bgo/instruction'
require 'bgo/model_item'

module Bgo

=begin rdoc
A definition of an address in an Image (e.g. the contents of a File or
Process).
Note that the contents of the address determine its properties, e.g. the
type of address (code or data), what it references, etc.
TODO: handle references TO address.

This is the base class for Address objects. It also serves as an in-memory
object when there is no backing store.
=end
  class Address
    extend Bgo::ModelItemClass
    include Bgo::ModelItemObject

=begin rdoc
The address contains an Instruction object.
=end
    CONTENTS_CODE = :code
=begin rdoc
The address contains a data object (pointer, variable, etc)
=end
    CONTENTS_DATA = :data
=begin rdoc
The address contains no content object, i.e. just raw bytes.
=end
    CONTENTS_UNK  = :unknown
=begin rdoc
An ImageChangeset::ImageAccessor wrapper for the Image containing the bytes.
=end
    attr_reader :image
=begin rdoc
Offset of address in image.
=end
    attr_reader :offset
=begin rdoc
Load address (VMA in process, offset in file).
=end
    attr_reader :vma
=begin rdoc
Size (in bytes) of address.
=end
    attr_reader :size

=begin rdoc
Contents of Address (e.g. an Instruction object).
=end
    attr_reader :contents_obj

=begin rdoc
Names (symbols) applied to the address or its contents.

This is a hash of id-to-name mappings:
  :self => name of address or nil
  0 => name to use in place of first operand
  1 => name to use in place of second operand
...etc.

Storing the names in-address (and applying them to operands) removes the
need for explicit scoping.
=end
# In Git: if n.to_i.to_s == n, name = n else name = n.to_sym
    attr_reader :names

=begin rdoc
An Array of Reference objects.
=end
    attr_reader :references

    # ----------------------------------------------------------------------
    def self.dependencies
      # TODO: static instruction definitions [to save mem]
      [ Bgo::Image ] # Bgo::Instruction
    end

    # TODO: child iterators e.g. code data

    # ----------------------------------------------------------------------
    def initialize( img, offset, size, vma=nil, contents=nil )
      @image = img  # Note : this allows @image to be nil
      @offset = offset
      @size = size
      @vma = vma || offset
      @contents_obj = contents
      @names = {}
      @references = []
      modelitem_init
    end

    alias :ident :vma

    def self.ident_str(vma)
      "0x%02X" % vma
    end

    def ident_str
      self.class.ident_str(vma)
    end

=begin rdoc
Convenience function that returns the load address (VMA) of the last byte in
the Address. An Address is a sequence of bytes from vma to end_vma.
=end
    def end_vma
      vma + size - 1
    end

=begin rdoc
Return String of (binary) bytes for Address. This uses @container#[]
=end
    def raw_contents
      (image || [])[offset,size]
    end

=begin rdoc
Iterator over raw_contents
=end
    def bytes
      raw_contents.bytes
    end

=begin rdoc
Return contents of Address, or bytes in address if Contents object has not
been set.
=end
    def contents
      contents_obj || raw_contents
    end

    def contents=(obj)
      @contents_obj = obj
    end

=begin rdoc
Nature of contents: Code, Data, or Unknown.
This saves an awkward comparison on contents.class for what is a commonly-performed operation.
=end
    def content_type
      return CONTENTS_UNK if not contents_obj
      (contents_obj.kind_of? Bgo::Instruction) ? CONTENTS_CODE : CONTENTS_DATA
    end

=begin rdoc
Return true if argument is a valid content type.
=end
    def self.valid_content_type?(str)
      sym = str.to_sym
      [CONTENTS_UNK, CONTENTS_CODE, CONTENTS_DATA].include? sym
    end

=begin rdoc
Return true if Address contains an Instruction object.
=end
    def code?
      content_type == CONTENTS_CODE
    end

=begin rdoc
Return true if Address is not code.
=end
    def data?
      content_type != CONTENTS_CODE
    end

    def name(ident=:self)
      self.names[ident]
    end

    def set_name(ident, str)
      # Note: git impl overrides this method, so '@' must be used, not 'self.'
      @names[ident] = str
    end

    def name=(str)
      add_name(:self, str)
    end

    def add_ref_to(vma, access='r--')
      # TODO
      # ref = ReferenceToAddress.new(vma, access)
      # self.references << ref
      # add_ref_from ?
    end

    def add_ref_from(vma, access='r--')
      # TODO
      # ditto
    end
    
    # ----------------------------------------------------------------------
  
    def image=(img)
      raise "Invalid Image #{img.class.name}" if (! img.respond_to? :[])
      @image = img
    end

=begin rdoc
Return (and/or yield) a contiguous list of Address objects for the specified
memory region. 
addrs is a list of Address objects defined for that region.
image is the Image object containing the bytes in the memory region.
load_addr is the VMA of the Image (vma for Map, or 0 for Sections).
offset is the offset into Image to start the region at.
length is the maxium size of the region

This is used by Section and Map to provide contiguous lists of all Addresses
they contain.
=end

    def self.address_space(addrs, img, load_addr, offset=0, length=0)
      # this method could use some refactoring, maybe into a standalone
      # address_space object that gets built from a PatchableByte container
      list = []
      length = (img.size - offset) if length == 0
      prev_vma = load_addr + offset
      prev_size = 0

      addrs.each do |a|
        prev_end = prev_vma + prev_size
        if prev_end < a.vma
          # create new address object 
          addr = Bgo::Address.new(img, prev_end - load_addr, a.vma - prev_end,
                                  prev_end)
          yield addr if block_given?
          list << addr
        end

        yield a if block_given?
        list << a
        prev_vma = a.vma; prev_size = a.size
      end

      # handle edge cases
      if list.empty?
        # handle empty list
        addr = Bgo::Address.new(img, offset, length, load_addr)
        yield addr if block_given?
        list << addr
      else 
        # handle empty space at end of section
        last_vma = list.last.vma + list.last.size
        max_vma = load_addr + offset + length
        if last_vma < max_vma
          addr = Bgo::Address.new(img, last_vma - load_addr, 
                                  max_vma - last_vma, last_vma)
          yield addr if block_given?
          list << addr
        end
      end
      list
    end

    # ----------------------------------------------------------------------
    def to_s
      # TODO: contents-type, flags, etc
      "%08X (%d bytes)" % [vma, size]
    end

    def inspect
      # TODO: bytes or contents
      "%08X %s, %d bytes" % [vma, content_type.to_s, size]
    end

    def hexdump
      hex = []
      bytes.each { |b| hex << "%02X" % b }
      hex.join(" ")
    end

=begin rdoc
Return an ASCII representation of the address contents. 
This will invoke Address#contents.ascii, if the contents object provides it.
Otherwise, Address#hexdump is invoked.
=end
    def ascii
      (@contents_obj.respond_to? :ascii) ? @contents_obj.ascii : hexdump
    end

=begin rdoc
Return contents of Address as an encoded String.
Example:
  addr.to_encoded_string(Encoding:UTF-8)
=end
    def to_encoded_string(encoding=Encoding::ASCII_8BIT)
      raw_contents.dup.force_encoding(encoding)
    end

    def to_core_hash
      { :size => @size,
        :vma => @vma,
        :offset => @offset,
        # Note: content_type is not de-serialized but it is nice to have in JSON
        :content_type => self.content_type
      }.merge(to_modelitem_hash)
    end

    def to_hash
      to_core_hash.merge( {
        :contents => (@contents_obj ? @contents_obj.to_hash : nil)
        # TODO: names 
        # TODO: references
      })
    end
    alias :to_h :to_hash

    def fill_from_hash(h)
      fill_from_modelitem_hash h
      # self.image is nil or Bgo::Image

      # instantiate contents based on type
      self.contents = AddressContents.from_hash(h)

      # TODO: names bindings
      # TODO: references
      self
    end

    # TODO: determine if proj is needed for any instantiation besides Image
    def self.from_hash(h, img=nil)
      return nil if (! h) or (h.empty?)
      self.new( img, h[:offset].to_i, h[:size].to_i, h[:vma].to_i 
              ).fill_from_hash(h)
    end

    protected

    def contents_obj=(obj)
      @contents_obj = obj
    end

  end

=begin rdoc
Reference to an Address. 
This encodes the address map, vma, and changeset.
=end
  class AddressRef
    # TODO: reference type? e.g. read, write, exec
    attr_reader :map, :vma, :changset

    def initialize(map, vma, cs=map.current_changeset)
      @map = map
      @vma = vma
      @changeset = cs
    end

    def address
      map.address(vma, changeset)
    end
  end

end
