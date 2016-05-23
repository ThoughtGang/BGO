#!/usr/bin/env ruby                                                             
# :title: Bgo::ByteContainer
=begin rdoc
Abstract base class for objects containing bytes. Its primary derived class is
AddressContainer (e.g. Buffer, Map, and Section).

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

Note that that ByteContainer does not manage addresses : that functionality
is provided by Changeset, which is wrapped by AddressContainer.
=end

require 'bgo/arch_info'

module Bgo

=begin rdoc
A container of bytes. This wraps an Image, associating it with a VMA.
=end
  class ByteContainer

=begin rdoc
Starting address (VMA).
=end
    attr_reader :start_addr
=begin rdoc
An Image object for the bytes in the container.
=end
    attr_reader :image
=begin rdoc
Number of bytes in container.
=end
    attr_reader :size

=begin rdoc
Offset into image of bytes in the container.
For Buffer objects this will always be 0; Map and Section objects will often
represent only a subset of the bytes in Image.
=end
    attr_reader :image_offset
    alias :offset :image_offset

=begin rdoc
Architecture information for the bytes in the container. This is an 
ArchInfo object. It is included here largely for convenience, to make the 
ByteContainer object relatively autonomous. 
=end
    attr_accessor :arch_info

    def initialize(image, vma=0, offset=0, sz=nil, arch_info=nil)
      @image = image
      @start_addr = vma || 0
      @image_offset = offset || 0
      @size = sz || image.size - offset
      @arch_info = arch_info || ArchInfo.unknown()
    end

    # ----------------------------------------------------------------------
=begin rdoc
Return a binary substring of the contents
=end
    def [](*args)                                                               
      # TODO: change args from vma to offset!
      contents.[](*args)
    end

=begin rdoc
Convert a VMA to an offset.
=end
    def vma_offset(vma)
      addr = vma - start_addr
      (addr < 0 || addr >= size) ? nil : addr
    end

=begin rdoc
Convert a VMA to an offset into the underlying Image.
=end
    def vma_image_offset(vma)
      vma_offset(vma) + image_offset
    end

=begin rdoc
Convert an offset to a VMA.
=end
    def offset_vma(offset)
      return nil if (offset < 0 || offset >= size)
      start_addr + offset
    end

=begin rdoc
Convert an offset into the underlying Image to a VMA.
=end
    def image_offset_vma(offset)
      offset_vma(offset - image_offset)
    end

=begin rdoc                                                                     
Return the max address in the map.
=end
    def max
      start_addr + size - 1
    end

=begin rdoc
Return true if byte container contains vma.
=end
    def contains?(vma)
      start = start_addr
      start && vma >= start && vma < (start + size)
    end

=begin rdoc
Return true if byte container contains specified offset into its Image.
=end
    def contains_image_offset?(offset)
      (offset >= image_offset) && (offset < image_offset + size)
    end

=begin rdoc
Return the contents of this byte container as a binary String.
=end
    def contents
      image.contents[image_offset, size]
    end

=begin rdoc
Iterator over bytes in container
=end
    def bytes
      contents.bytes
    end

    def io
      StringIO.new(contents)
    end

    # ----------------------------------------------------------------------
    def to_core_hash
      {
        :start_addr => @start_addr,
        :image => @image.ident,
        :image_offset => @image_offset,
        :size => @size,
        :arch_info => (self.arch_info ? self.arch_info.to_hash : nil)
      } 
    end

    def to_hash
      to_core_hash
    end
    alias :to_h :to_hash

    def fill_from_hash(h)
      @arch_info = Bgo::ArchInfo.from_hash h[:arch_info] if h[:arch_info]
      self
    end

    # NOTE: this is here for completeness but isn't actually called
    def self.from_hash(h, proj=nil)
      img_ident = h[:image]
      img = h[:image_obj]
      if proj && img_ident
        img ||= proj.image(img_ident)
        img ||= proj.item_at_obj_path img_ident
      end

      self.new(img, h[:vma].to_i, h[:image_offset].to_i, h[:size].to_i
              ).fill_from_hash(h)
    end

  end
end
