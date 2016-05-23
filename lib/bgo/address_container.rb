#!/usr/bin/env ruby                                                             
# :title: Bgo::AddressContainer
=begin rdoc
Abstract base class for objects containing bytes and Address objects which
may go through changes or Revisions. Subclasses include Map and Section.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

Formerly PatchableByteContainer
=end

require 'forwardable'

require 'bgo/block'
require 'bgo/byte_container'
require 'bgo/image_changeset'

# TODO: Implement []

module Bgo

=begin rdoc
A ByteContainer whose contents can be patched, and which associates Address
objects with bytes of a specific Revision.

This associates an ImageChangeset with a ByteContainer.

The ImageChangeset is not directly exported. All management of the 
ImageChangeset and its Revisions must take place through this class.
=end
  class AddressContainer < ByteContainer

    extend Forwardable

=begin rdoc
Exception raised when an Address is added that overlaps an existing
Address object in the ByteContainer.

This can occur for duplicate Address objects, or for Address objects that
contain addresses already allocated to another Address object.

This exception can be avoided by calling AddressContainer#exist? before 
calling AddressContainer#add_address. To force the new Address to be 
added, either delete the existing Address object or create a new revision via 
AddressContainer#add_revision.
=end
    class AddressExists < RuntimeError; end

=begin rdoc
The Image of the Address object being added to the Address Container does not
match the Image of the Revision to which it is being added.
This should not occur in practice; the solution is to manually set the revision
to one with the same Image and no conflicting Address objects.
=end
    class AddressImageMismatch < RuntimeError; end

=begin rdoc
Exception raised when a request (e.g. AddressContainer#add_address) 
would exceed the ByteContainer boundaries.
=end
    class BoundsExceeded < RuntimeError; end

    # Create alias for original ByteContainer image() accessor
    alias :base_image :image
    alias :orig_image :image

    # All revision, address, and image methods are forwarded to ImageChangeset
    def_delegators :@changeset, :revision, :revision=, :revisions,
                   :add_revision, :remove_revision, :import_revision, 
                   :current_revision, :remove_address, :address, :image, 
                   :patch_bytes

=begin rdoc
Outer block of AddressContainer. All blocks are defined as children of this
block.
=end
    attr_reader :block

    def initialize(base_image, vma=nil, offset=0, size=nil, arch_info=nil)
      super base_image, vma, offset, size, arch_info
        
      @changeset = ImageChangeset.new(base_image, vma)
      @changeset.parent_modelitem = self
      # Note: parent of AddressContainer sets @block.scope.parent to its scope
      @block = Block.new(vma, size)
      @block.container = self
    end

=begin rdoc
Returns contents (bytes) of container as a binary String
=end
    def contents(rev=nil)
      @changeset.image(rev).contents[image_offset, size]
    end

=begin rdoc
Iterator over bytes in container
=end
    def bytes(rev=nil)
      contents(rev).bytes
    end

=begin rdoc
Return an IO object for the contents of the image.
The caller is expect to close the IO object.
=end
    def io(rev=nil)
      StringIO.new(contents, rev)
    end

    # ----------------------------------------------------------------------
    # Addresses

=begin rdoc
Return true if an Address object exists for vma. This checks that whether any
defined Address object contains vma. If an Address object exists at offset
0x100 with a size of 4 bytes, then Map#exist? will return true for 0x100,
0x101, 0x102, and 0x103.

Note: This only checks Address objects defined in the specified revision
unless recurse is true (the default behavior).
=end
    def exist?(vma, recurse=true, rev=nil)
      range_exist? vma, 1, recurse, rev
    end

=begin rdoc
Return true if the range of addresses exists in any defined Address object(s)
in the specified revision.
If recurse is true, this also checks all revision lower than the specified
revision. This is the default behavior.
=end
    def range_exist?(vma, size, recurse=true, rev=nil)
      addrs = recurse ? address_range(vma, size, rev, false) :
                        @changeset.addresses(rev).values.reject do |a|
        a.end_vma < vma || a.vma >= vma + size
      end

      addrs.count > 0
    end

=begin rdoc
List all Address objects defined in Map.

By default, this invokes address_range on the specified revision and
returns a list of all valid Address objects. This means that Address objects
defined in previous revisions will be included if their addresses were not
redefined by a later revision.

To restrict the list of Addresses to ONLY those defined in the specified 
revision, set recurse to false.

Note: Use contiguous_addresses to get a complete address range with virtual 
Address objects filling all gaps.
=end
    def addresses(rev=nil, recurse=true, ident_only=false, &block)
      return to_enum(:addresses, rev, recurse, ident_only) if ! block_given?
      addrs = recurse ? address_range(start_addr, size, rev, true) :
                        @changeset.addresses(rev).values
      addrs.each { |addr| yield(ident_only ? addr.vma : addr) }
    end

=begin rdoc
Return an Array of all Address objects that exist in range. This checks
all Revisions from 'rev' to the Empty/Base Revision for Address objects.

The 'strict' argument controls how the range bounds are treated. If the start
or end of the range lies inside an existing Address object, that Address object
is included in the list *unless* strict is true.
=end
    def address_range(start_vma, len, rev=nil, strict=false)

      # Note: this method just wraps build_address_range to hide the
      #       dual strict variables needed during recursion
      build_address_range(start_vma, len, rev, strict, strict)
    end


=begin rdoc
Return (and/or yield) a contiguous list of Address objects in the Map.
Gaps between defined Address objects will be filled with an Address object
that spans the gap; this Address object is not stored in the Project.
=end
    def contiguous_addresses(rev=nil, &block)
      Bgo::Address.address_space( addresses(false, true, rev), image(rev),
                                  start_addr, offset, size, &block )
    end

=begin rdoc
Return (and/or yield) a contiguous list of Address objects in the specified
range of the Map.
See. Map#contiguous_addresses.
=end
    def contiguous_range(start_vma, len, rev=current_rev, strict=false,
                         &block)
      Bgo::Address.address_space(address_range(start_vma, len, rev, strict),
                                 image(rev), start_addr, offset, size, &block)
    end

=begin rdoc
Return an Address object inside this AddressContainer that matches the
provided object path.

This accepts object paths of the following formats:
  VMA
  VMA/rev/REV
  address/VMA
  address/VMA/rev/REV

Other object path formats (e.g. process/PID/address/VMA) will return nil.

Examples:
  # get Address at 0x80401000 in the current revision
  map.instantiate_address_from_path "0x80401000"
  map.instantiate_address_from_path "address/0x80401000"
  # get Address at 0x80401000 in revision 1
  map.instantiate_address_from_path "0x80401000/revision/1"
  map.instantiate_address_from_path "address/0x80401000/revision/1"
=end
    def instantiate_address_from_path(objpath)
      return nil if (! objpath) or (objpath.empty?)

      # extract "/revision/#" suffix if it exists 
      addrpath, rev = objpath.split('/revision/') 
      rev = rev.to_i if rev
      begin
        # parse either "address/0xVMA" or "0xVMA"
        address(Integer(addrpath.sub(/^address\//, '')), rev)
      rescue ArgumentError
        nil
      end
    end

=begin rdoc
Return an Address object (if provided an Index), or an Array of Address objects
(if provided a Range or Slice), in AddressContainer. If provided a Range
argument, the Range#step member is ignored (steps make no sense in an Address
context). This method applies to the current revision and is recursive to 
previous revisions.
Note: This uses address_range with strict set to true.
=end
    def [](*args)
      start_vma = len = nil
      if args.length == 1
        arg = args.first
        if arg.kind_of? Numeric
          return @changeset.address(args.first)
        elsif arg.kind_of? Range
          # NOTE: step argument is ignored
          start_vma = arg.begin
          len = arg.max - start_vma + 1
        end
      elsif args.length == 2
        start_vma = args.first.to_i
        len = args.last.to_i
      end
      return address_range(start_vma, len, nil, true) if start_vma and len

      raise ArgumentError, "Not an index, slice, or range"
    end

=begin rdoc
Define Address object at VMA in the specified revision of the AddressContainer.
If 'strict' is true, then AddressExists will be returned if an Address has
already been defined
=end
    def add_address(vma, len, rev=nil, strict=false)
      addr_offset = vma - start_addr
      raise BoundsExceeded if (addr_offset < 0 || addr_offset + len > size)
      raise AddressExists if range_exist?(vma, len, false, rev)
      @changeset.add_address(addr_offset, vma, len, rev)
    end

=begin rdoc
Add an Address object to this Address container.
NOTE: If an the new Address overlaps with an existing Address in the current
revision, a new revision will be created, and will become the current revision.
This may not be the intended effect, so application/plugin developers should
be wary.
WARNING: If the Address Image does not match the Revision Image, an
AddressImageMismatch will be raised. This can happen if an Address conflicts 
with an existing Address in the Revision, causing a new Revision to be created, 
=end
    def add_address_object(obj, rev=nil)
      # 1. check if an identical Address object exists
      @changeset.addresses_for_vma(obj.vma).each do |r, addr|
        if obj.vma == addr.vma &&
           obj.size == addr.size &&
           obj.content_type == addr.content_type &&
           # NOTE: this can be made a straight == if all
           #       data contents objects support it
           obj.contents_obj.inspect == addr.contents_obj.inspect
          return addr
        end
      end
      
      # 2. Create a new revision if Address exists in specified revision
      #    FIXME: Ensure that subsequent revisions (after current) do not
      #           exist -- or, if they do, that they have not been patched
      #           (and if they haven't, and do not contain the address, use
      #           them).
      rev ||= current_revision
      if range_exist?(obj.vma, obj.size, false, rev)
        @changeset.add_revision
        rev = current_revision
      end

      # FIXME: This will never work as Address always links to the base image!
      #        Need to verify that a) base_image is the same, and b)
      #        base image has not changed between AC revision and Address
      #        ImageAccessor.
      # 3. Verify that the Address has the same Image as the current revision
      #if (obj.image.ident != image(rev).ident)
      #  raise AddressImageMismatch
      #end
      # FIXME: If the images conflict, there should be a means to insert a
      #        revision in between rev and one with patched bytes.
      #        This may cause problems if revision index is also its ident.

      # 4. Add the address object to the changeset
      @changeset.add_address_object(obj)
    end

=begin rdoc
Invoke block with current_revision set to the provided revision. This passes
self (AddressContainer) to the block.
=end
    def with_revision(rev, &block)
      old_rev = current_revision
      @changeset.revision= rev
      yield self
      @changeset.revision= old_rev
    end


    # ----------------------------------------------------------------------

    def to_hash
      { 
        :block => @block.to_hash,
        :changeset => @changeset.to_hash }.merge(super)
    end
    alias :to_h :to_hash

    def fill_from_hash(h)
      super
      @block = Block.from_hash h[:block]
      # Note: changeset is already set to use @base_image
      @changeset.fill_from_hash h[:changeset] if h[:changeset]
      self
    end

    # NOTE: this is here for completeness but isn't actually invoked
    def self.from_hash(h, img)
      self.new(img, h[:vma].to_i, h[:image_offset].to_i, h[:size].to_i
              ).fill_from_hash(h)
    end

    # ======================================================================
    protected

=begin rdoc
Backend for Map#address_range.
=end
    # FIXME: REFACTOR extract-method
    def build_address_range(start_vma, len, rev, strict_start, strict_end)
      rev ||= @changeset.current_revision
      img = image(0)  # no need for patching; this is just a size check
      len = img.size if len > img.size
      addrs = []
      rev_addrs = @changeset.addresses(rev)
      all_vmas = rev_addrs.keys.sort
      max_vma = start_vma + len - 1

      vma_list = build_vma_list(all_vmas, rev_addrs, start_vma, max_vma, 
                                strict_start, strict_end)

      addrs.concat fill_start_gap(all_vmas, rev_addrs, vma_list, start_vma, 
                                  rev, strict_start)

      # ==================================================
      # Fill addrs with Address objects from this revision
      # FIXME: Should this be part of Changeset?
      vma_list.each do |curr_vma|

        # Is there a gap between previous Address object and this one?
        if addrs.last
          next_addr = addrs.last.vma + addrs.last.size

          # RECURSE TO PREVIOUS REVISION
          if next_addr < curr_vma
            # ... if yes, then fill the gap based on the previous revision
            # Note that this gap is ALWAYS strict
            addrs.concat build_address_range(next_addr, curr_vma - next_addr, 
                                            rev - 1, true, true) unless rev <= 0
          end
        end

        # Do not add address if it extends beyond max_vma (unless !strict)
        a = rev_addrs[curr_vma]
        addrs << a if (not strict_end) || a.end_vma <= max_vma
      end

      addrs.concat fill_end_gap(addrs.last, start_vma, max_vma, rev, strict_end)
      addrs
    end

=begin rdoc
Helper method for build_address_range. Generates a list of vmas to process.
=end
    # FIXME: REFACTOR extract-method
    def build_vma_list(all_vmas, rev_addrs, start_vma, max_vma, strict_start, 
                       strict_end)

      # Restrict vma_list to Addresses in requested range
      vma_list = all_vmas.reject do |vma| 
        vma < start_vma || rev_addrs[vma].end_vma > max_vma
      end

      # ==================================================
      # Include Addresses that extend beyond bounds 
      # Note: this is a 'principle of least surprise' feature. Unless strict,
      #       Address objects *containing" requested addresses are returned.

      # If first Address is > start_vma, add the preceding Address
      if not strict_start && (not vma_list.include? start_vma)

        # Find Address object that contains start_vma
        prev_vma = nil
        all_vmas.each do |v| 
          prev_vma = v if (v < start_vma && rev_addrs[v].end_vma >= start_vma)
        end
        vma_list.unshift( prev_vma ) if prev_vma
      end

      # ==================================================
      # If last Address is < max_vma, add the succeeding Address
      if not strict_end
        last_vma = vma_list.count > 0 ? rev_addrs[vma_list.last].end_vma : 
                                        start_vma

        # This is kind of tricky, as start_vma may equal max_vma when
        # vma_list is empty (e.g. during an end-fill)
        if (last_vma == start_vma) || last_vma < max_vma

          # Find Address object that contains max_vma
          next_vma = nil
          all_vmas.reverse.each do |v|
            next_vma = v if (v <= max_vma && rev_addrs[v].end_vma >= max_vma)
          end
          vma_list.push( next_vma ) if next_vma
        end

      end

      vma_list
    end

=begin rdoc
Helper method for build_address_range. Fills gap at start of address range
with contents of previous revisions.
=end
    def fill_start_gap(all_vmas, rev_addrs, vma_list, start_vma, rev, 
                       strict_start)

      # Is there a gap between start_vma and the first Address object?
      return [] if (vma_list.count == 0 || vma_list.first <= start_vma ||
                    rev == 0)

      # If start addr is inside an Address, then start *after* that Address
      idx = all_vmas.index(vma_list.first)
      prev_vma = all_vmas[idx-1]
      the_vma = (prev_vma && rev_addrs[prev_vma].end_vma >= start_vma) ?
                 rev_addrs[prev_vma].end_vma + 1 : start_vma

      # Fill the gap based on the previous revision
      build_address_range(the_vma, vma_list.first - the_vma, rev - 1, 
                          strict_start, true)
    end

=begin rdoc
Helper method for build_address_range. Fills gap at end of address range with
contents of previous revision.
=end
    def fill_end_gap(last_addr, start_vma, max_vma, rev, strict_end)
      # ==================================================
      # Is there a gap between the last Address object and max_vma?
      last_vma = last_addr ? last_addr.end_vma + 1 : start_vma
      return [] if (last_vma > max_vma || rev == 0)

      # Fill the gap based on the previous revision
      build_address_range(last_vma, max_vma - last_vma + 1, rev - 1, true, 
                          strict_end)
    end

  end
end
