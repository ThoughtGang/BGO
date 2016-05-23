#!/usr/bin/env ruby
# :title: Bgo::ImageRevision
=begin rdoc
BGO ImageRevision object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/address'
require 'bgo/model_item'

module Bgo

=begin rdoc
Revision for a Bgo::Image object. This is managed by a Bgo::ImageChangeset.

This contains Address objects and byte patches to the base Image object that
are defined in this ImageRevision.

Note that the Image object is not included in the ImageRevision. Thus, 
ImageRevision objects are dependent on their parent ImageChangeset object.
=end
  class ImageRevision
    extend Bgo::ModelItemClass
    include Bgo::ModelItemObject


=begin rdoc
An identifier (usually an integer or revision number) for the changeset.
=end
    attr_reader :ident

=begin rdoc
Hash of vma->Fixnum objects
=end
    attr_reader :changed_bytes

    def self.dependencies
      [ Bgo::Address ]
    end

    def self.path_elem
      'revision'
    end

    def self.child_iterators
      [ :addresses ]
    end

    def instantiate_child(objpath, recurse_parent=true, recurse_child=false)
      super objpath, recurse_parent, false
    end

=begin rdoc
The is_empty parameter determines whether this is the empty changeset.

An empty changeset represents the base image of the Map: it may have
addresses defined, but cannot be patched.
=end
    def initialize(ident, is_empty=false)
      @ident = ident.to_i
      @is_empty_changeset = is_empty
      clear

      modelitem_init
    end

=begin rdoc
Returns false if this is the empty changeset, true otherwise.
=end
    def patchable?
      not @is_empty_changeset
    end

=begin rdoc
Patch bytes in the changeset. This applies the bytes in the String 'bytes' to
the changeset starting at the specified VMA. Existing changes for
affected VMAs will be overwritten.

Note: This returns false if the changeset cannot it not patchable.
=end
    def patch_bytes(vma, bytes)
      return false if not patchable?
      bytes.length.times { |i| @changed_bytes[vma+i] = bytes[i] }
      true
    end

    def clear_changed_bytes
      @changed_bytes = {}
    end

    def patched?
      (! @change_bytes.empty?)
    end

=begin rdoc
This stores the Address object 'addr' at the specified VMA. It does not check
if the address already exists.
=end
    def add_address(vma, addr)
      @addresses[vma] = addr
      addr.modelitem_init_parent self
      addr
    end

=begin rdoc
Removes Address object at the specified VMA.
=end
    def remove_address(vma)
      @addresses.delete(vma)
    end

=begin rdoc
Return hash of Address objects. This can be overridden by child classes
(e.g. Git::Image) to provide an alternate implementation.
=end
    def address_hash
      @addresses.dup
    end

=begin rdoc
Return the Address object for the specified VMA. This can be overridden by 
child classes to provide an alternate implementation.
=end
    def address(vma)
      @addresses[vma]
    end

=begin rdoc
List Address objects in ImageRevision
=end
    def addresses(ident_only=false, &block)
      list = []
      @addresses.values.sort_by { |a| a.vma }.each do |addr|
        a = ident_only ? addr.vma : addr
        yield a if block_given?
        list << a
      end
      list
    end

    def clear_addresses
      @addresses = {}                 # Hash of vma->Address objects
    end

=begin rdoc
Clear Addresses and patched bytes stored in Revision.
=end
    def clear
      clear_changed_bytes
      clear_addresses
    end

    # ----------------------------------------------------------------------
    def to_s
      ident.to_s
    end

    def inspect
      "%s:%08X(rev-%d)" % [self.class.name, self.object_id, ident]
    end

    # ----------------------------------------------------------------------

    def to_core_hash
      {
        :ident => @ident,
        :is_empty => @is_empty_changeset
      }.merge(to_modelitem_hash)
    end

    def to_hash
      to_core_hash.merge( {
        :changed_bytes => @changed_bytes,
        :addresses => @addresses.values.map { |a| a.to_hash }
      })
    end
    alias :to_h :to_hash

    def fill_from_hash(h, img)
      fill_from_modelitem_hash h
      (h[:addresses] || []).each do |a|
        # NOTE: this leaves Address#image set to nil. The Revision MUST
        #       be imported into a Revision to fix the Address objects!
        add_address a[:vma].to_i, Address.from_hash(a, img)
      end

      (h[:changed_bytes] || {}).each do |vma, byte|
        patch_bytes(vma.to_i, [byte.to_i])
      end

      self
    end

    # Note: img is just forwarded to Address.from_hash
    def self.from_hash(h, img)
      return nil if (! h) or (h.empty?)
      self.new(h[:ident].to_i, h[:is_empty]).fill_from_hash(h, img)
    end

  end

end
