#!/usr/bin/env ruby
# :title: Bgo::Map
=begin rdoc
BGO Map object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end  

require 'bgo/address_container'
require 'bgo/image'
require 'bgo/model_item'

module Bgo

=begin rdoc
A Memory Mapping. This maps a portion of an Image into a Process address space.

This is the base class for Map objects. It also serves as an in-memory object
when there is no backing store.
=end
  class Map < Bgo::AddressContainer
    extend Bgo::ModelItemClass
    include Bgo::ModelItemObject

=begin rdoc
List of flags for mapped memory (e.g. RWX).
=end
    attr_accessor :flags

    alias :vma :start_addr
    alias :ident :start_addr

    FLAG_READ = 'r'
    FLAG_WRITE = 'w'
    FLAG_EXEC = 'x'
    FLAGS = [ FLAG_READ, FLAG_WRITE, FLAG_EXEC ]
    DEFAULT_FLAGS = [ FLAG_READ, FLAG_WRITE ]

    def self.dependencies
      [ Bgo::Image ] # Bgo::Process?
    end

    def self.child_iterators
      [ :addresses ]
    end

    def self.default_child
      :address
    end

    # ----------------------------------------------------------------------

=begin rdoc
Instantiate a Map object
=end
    def initialize( start_addr, img, offset=0, size=nil, flags=DEFAULT_FLAGS,
                    arch_info=nil )
      size ||= img.size
      max_size = img.size - offset
      size = max_size if size > max_size

      super img, start_addr, offset, size, arch_info

      @flags = flags.dup

      modelitem_init
    end

=begin rdoc
Set size of Map.
=end
    def size=(num)
      raise "Cannot have negative size" if num < 0
      raise "#{num} > image size" if image_offset + num >= base_image.size
      check_for_addrs_before_resize(start_addr, image_offset, num)
      @size = num
    end

    def self.ident_str(load_addr)
      "0x%08X" % load_addr
    end

    def ident_str
      self.class.ident_str(start_addr)
    end

=begin rdoc
Set image offset of Map.
=end
    def offset=(num)
      raise "Cannot have negative file offset!" if num < 0
      raise "#{num} > image size" if num + size >= base_image.size
      check_for_addrs_before_resize(start_addr, num, size)
      @image_offset = num
    end

=begin rdoc
Set start address (VMA) of Map.
=end
    def start_addr=(num)
      @start_addr = num
    end
    alias :vma= :start_addr=

=begin rdoc
Strip invalid flags from flags array
=end
    def self.validate_flags( flags )
      return [] if not flags
      flags.reject { |f| not FLAGS.include? f }
    end

=begin rdoc
Return last valid address in Map.
=end
    def end_addr
      self.start_addr + self.size - 1
    end

=begin rdoc
Return true if Map overlaps memory region of 'size' bytes at VMA 'addr'.
=end
    def overlap?(addr, sz)
      max_addr = addr + sz - 1
      return true if (contains? addr) or (contains? max_addr)
      (start_addr > addr && start_addr < max_addr && end_addr > addr && 
       end_addr < max_addr)
    end

=begin rdoc
Return true if mapped memory is executable.
=end
    def executable?
      flags.include? FLAG_EXEC
    end

=begin rdoc
Return true if mapped memory is readable.
=end
    def readable?
      flags.include? FLAG_READ
    end

=begin rdoc
Return true if mapped memory is writeable.
=end
    def writeable?
      flags.include? FLAG_WRITE
    end

=begin rdoc
Return flags as a string.                                                       
=end
    def flags_str
      FLAGS.map { |f| (flags.include? f) ? f : '-' }.join('')
    end

    #def add_address(vma, len, rev=nil)
    #  a = super
    #  a.modelitem_init_parent self
    #  a
    #end

    # ----------------------------------------------------------------------
    # Override ModelItemObject#instantiate_child so that recurse_child
    # is always false.
    def instantiate_child(objpath, recurse_parent=true, recurse_child=false)
      # TODO: remove enforced false if block children are supported

      # Note: an address objpath that fails the first call will fail the second
      instantiate_address_from_path(objpath) || 
        super(objpath, recurse_parent, false)
    end

    # ----------------------------------------------------------------------
    def to_s
      "Map 0x%X" % start_addr
    end

    def inspect
      vma = "0x%X" % start_addr
      "Map #{vma}: #{size} bytes"
    end

    def to_core_hash
      { :flags => self.flags 
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
      self.new( h[:start_addr].to_i, img, h[:image_offset].to_i, h[:size].to_i 
              ).fill_from_hash(h)
    end


# ----------------------------------------------------------------------
    protected

=begin rdoc
Raise an exception if Map contains addresses that lie outside of proposed
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
