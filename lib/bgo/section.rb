#!/usr/bin/env ruby
# :title: Bgo::Section
=begin rdoc
==BGO Section object
<i>Copyright 2013 Thoughtgang <http://www.thoughtgang.org></i>

A Section is a contiguous sequence of bytes in a TargetFile. This is normally
used in object file formats to distiguish between code, data, and metadata
(e.g. headers, dynamic linking info, symbol tables) in the TargetFile.

A BGO Section is mainly used as a container for Address objects inside a 
TargetFile. A TargetFile itself does not store Address objects, and so every
TargetFile should have at least one Section spanning its entire contents if
it is going to be used as an analysis target. Section objects cannot be nested.
=end  

require 'bgo/address_container'
require 'bgo/model_item'

# FIXME: resizing a section could cause existing addresses to lie outside
#        it. This should raise an exception.

module Bgo

=begin rdoc
A Section of a File. Generally a section is a portion of the file that
is mapped into memory.

This is the base class for Section objects. It also serves as an in-memory
object when there is no backing store.
=end
  class Section < Bgo::AddressContainer
    extend Bgo::ModelItemClass
    include Bgo::ModelItemObject

=begin rdoc
Section identifier. This is an arbitrary String, though Parser plugins 
generally use an index into a table of sections.
=end
    attr_reader :ident
=begin rdoc
The name of the section. Not all sections have names.
=end
    attr_accessor :name
=begin rdoc
Offset of Section in TargetFile. Note that this may be different from the
offset of the ByteContainer in the Image.
=end
    attr_reader :file_offset
    alias :offset :file_offset
=begin rdoc
List of flags for section (e.g. RWX).
=end
    attr_accessor :flags

    FLAG_READ = 'r'
    FLAG_WRITE = 'w'
    FLAG_EXEC = 'x'
    FLAGS = [ FLAG_READ, FLAG_WRITE, FLAG_EXEC ]
    DEFAULT_FLAGS = [ FLAG_READ, FLAG_WRITE ]

# ----------------------------------------------------------------------
    # Override ModelItemObject#instantiate_child so that recurse_child 
    # is always false.

    def self.dependencies
      [ Bgo::Image ] # Bgo::TargetFile?
    end

    def self.child_iterators
      # TODO: revisions? blocks?
      [ :addresses ]
    end

    def self.default_child
      [ :address ]
    end

# ----------------------------------------------------------------------

=begin rdoc
Instantiate a Section object
=end
    def initialize( ident, name, img, img_off=0, file_off=0, sz=nil,
                    flags=DEFAULT_FLAGS )
      @file_offset = file_off
      super img, file_off, img_off, sz
      @ident = ident.to_s
      @name = name
      @flags = flags.dup
      @addresses = {}

      modelitem_init
    end

=begin rdoc
Set size of Section.
=end
    def size=(num)
      raise "Cannot have negative size!" if num < 0
      raise "#{num} > image size" if image_offset + num >= image.size
      check_for_addrs_before_resize(start_addr, image_offset, num)
      @size = num
    end

=begin rdoc
Set offset of Section. Note that this is applied directly to file_offset, and
the difference between the existing file_offset and the new file_offset is
applied to image_offset.
=end
    def file_offset=(num)
      raise "Cannot have negative file offset!" if num < 0
      diff = @file_offset - num
      raise "#{num} > image size" if image_offset + diff + size >= image.size
      raise "Cannot have negative image offset!" if image_offset - diff < 0
      check_for_addrs_before_resize(start_addr, num, size)
      @image_offset -= diff
      @file_offset = num
    end
    alias :offset= :file_offset=

=begin rdoc
Return flags as a string.
=end
    def flags_str
      FLAGS.map { |f| (flags.include? f) ? f : '-' }.join('')
    end

=begin rdoc
Strip invalid flags from flags array
=end
    def self.validate_flags( flags )
      return [] if not flags
      flags.reject { |f| not FLAGS.include? f }
    end

    #def add_address(offset, len, rev=nil)
    #  a = super
    #  a.modelitem_init_parent self
    #  a
    #end
    # ----------------------------------------------------------------------

    def instantiate_child(objpath, recurse_parent=true, recurse_child=false)
      # TODO: remove enforced false if block children are supported
      instantiate_address_from_path(objpath) ||
        super(objpath, recurse_parent, false)
    end 

    # ----------------------------------------------------------------------
    def to_s
      "Section #{name} [#{ident}]"
    end

    def inspect
      str = "Section #{ident} '#{name}' (#{flags_str}): #{size} bytes"
      ai = arch_info
      str << " [#{ai.to_s}]" if ai
      str
    end

    def to_core_hash
      { :ident => @ident,
        :name => @name,
        :file_offset => @file_offset,
        :flags => @flags
      }.merge(super).merge(to_modelitem_hash)
    end

    def to_hash
      to_core_hash.merge(super)
    end
    alias :to_h :to_hash

    def fill_from_hash(h)
      fill_from_modelitem_hash h

      @flags = (h[:flags] || []).map { |f| f.to_sym }
      super
      self
    end

    def self.from_hash(h, proj=nil)
      return nil if (! h) or (h.empty?)
      img = image_from_hash!(h, proj)
      # TODO: pass project here if needed in AddressContainer/etc
      self.new(h[:ident].to_s, h[:name].to_i, img, h[:image_offset].to_i, 
               h[:file_offset].to_i, h[:size].to_i).fill_from_hash(h)
    end


  # ----------------------------------------------------------------------
  protected

=begin rdoc
Return (and/or yield) a contiguous list of Address objects in the Section.
All gaps between defined Address objects will be filled by an Address object
spanning the gap; this Address object is not stored in the Project.
=end
    def contiguous_addresses(&block)
      Bgo::Address.address_space(addresses, image, 0, offset, size, &block)
    end

=begin rdoc
Raise an exception if Section contains addresses that lie outside of proposed
new boundaries.
=end
    def check_for_addrs_before_resize(vma, image_offset, num)
      # TODO
    end  

    def instantiate_child_from_ident(sym, ident)
      if sym == :revision
        ident = Integer(ident) rescue nil
      end
      super sym, ident
    end 

  end

end
