#!/usr/bin/env ruby                                                             
# :title: Bgo::ImageChangeset
=begin rdoc
BGO Image Changeset object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/address'
require 'bgo/image_revision'
require 'bgo/patched_image'

# NOTE: document VMA as being offset or VMA depending on context. VMA range
#       is NOT checked in Changeset; it is purely used to identify Addresses.

module Bgo

=begin rdoc
A sequence of Revisions to an Image.
Each revision is a collection of bytes that have changed in the Image, or
Address objects that have been defined on the Image.

Note that every Changeset begins with the Empty or Base Revision, in which
no bytes for the Image have changed. This initial revision cannot be deleted
or patched.
=end
  class ImageChangeset 

=begin rdoc
A wrapper for an Image object.
This stores the ImageChangeset and the Revision for an Image, and exposes a
slice or indexing method ImageAccessor#[] for accessing the Image contents.
The purpose of this class is to provide a proxy object which will access 
the bytes of an Image object following a specified revision.
=end
    class ImageAccessor
      attr_reader :changeset
      attr_reader :revision

      def initialize(cs, rev=nil)
        @changeset = cs
        @revision = rev || cs.current_revision
      end

      def image
        @changeset.image @revision
      end

      def [](*args)
        self.image.[](*args)
      end

      # TODO: support changeset address support as well?
    end

=begin rdoc
ID (index) of the current ImageRevision for the ImageChangeset.
=end
    attr_reader :current_revision
=begin rdoc
Unmodified Image object to which Revisions apply.
=end
    attr_reader :base_image
=begin rdoc
VMA of offset 0 in base image.
This is used to resolve VMAs to offsets.
=end
    attr_reader :start_addr

=begin rdoc
ModelItem parent passed on to Revisions.
This is not required for a Changeset to operate, but ModelItem objects 
should set it.
=end
    attr_accessor :parent_modelitem

    def initialize(base_image, base_vma=0)
      @base_image = base_image
      @start_addr = base_vma || 0
      
      @revisions = [ ImageRevision.new(0, true) ]
      @current_revision = 0
      @patched_image_cache = []
    end

=begin rdoc
Retrieve comment for revision (default: current).
=end
    def comment(rev=nil)
      rev ||= current_revision
      revision(rev).comment
    end

=begin rdoc
Set comment for revision. This overwrites any existing comment.
=end
    def comment=(cmt, rev=nil)
      rev ||= current_revision
      revision(rev).comment = cmt if (revision_exists? rev)
    end

    # ----------------------------------------------------------------------
    # Revisions
=begin rdoc
Return the specified revision object. By default, this is returns the current
revision.
=end
    def revision(ident=nil)
      @revisions[(ident || current_revision)]
    end

=begin rdoc
Set the current revision to specified ident. This raises an exception if the
specified revision does not exist.
=end
    def revision=(val)
      raise "No such revision" if (val < 0 || val >= @revisions.count)
      @current_revision = val
    end
    alias :current_revision= :revision=

=begin rdoc
Returns true if a Revision for 'rev' exists.
=end
    def revision_exists?(rev)
      rev >= 0 && rev < @revisions.count
    end

=begin rdoc
Return an array of the ImageRevision objects in the ImageChangeset. The index 
of a revision in the array is its id. Note that index 0 is the empty revision:
no patches can be added to it.
=end
    def revisions(ident_only=false, &block)
      return to_enum(:revisions, ident_only) if not block_given?
      @revisions.each do |rev|
        yield(ident_only ? rev.ident : rev) 
      end
    end

=begin rdoc
Iterate over all Revisions from the Empty Revision up to (and including)'rev', 
yielding each Revision object.
=end
    def upto(rev, &block)
      return to_enum(:upto, rev) if not block_given?
      (rev + 1).times { |i| yield revision(i) if (revision_exists? i) }
    end

=begin rdoc
Return the next revision object which has changed bytes, or nil.
=end
    def next_patched_revision(rev=nil)
      rev ||= current_revision
      (@revisions.count - (rev + 1)).times do |idx|
        r = revision(rev + 1 + idx)
        return r if r.patched?
      end
      nil
    end

=begin rdoc
Add a new revision to ImageChangeset. The new revision becomes the current 
revision.
Returns the new ImageRevision.
=end
    def add_revision
      ident = @revisions.count
      r = new_revision(ident, false)
      add_revision_object r
    end

=begin rdoc
Remove Revision from Changeset. If this is the latest revision, it is removed
from the end of the revisions Array; otherwise, it is replaced with an
empty Revision.
Note: the Empty or Base Revision (index 0) cannot be removed.
=end
    def remove_revision(rev)
      return false if rev == 0 || (! revision_exists? rev)
      if rev == (@revisions.count - 1)
        @revisions.pop
      else
        @revisions[rev] = new_revision(rev)
      end
      @current_revision = rev - 1 if (@current_revision == rev)
      true
    end

=begin rdoc
Remove all Addresses and ChangeBytes from specified Revision.
=end
    def clear_revision(rev)
      (revision_exists? rev) && revision(rev).clear
    end

=begin rdoc
Import changed bytes and Address objects from a Revision object into a new 
Revision. 
If r is the Empty Revision (ident 0), is Address objects are added to the
Empty Revision of the current Changeset, and no new Revision is created.
=end
    def import_revision(r)
      new_rev = (r.patchable?) ?  add_revision : @revisions[0] 
      new_rev.dup_modelitem r

      r.changed_bytes.each do |vma, byte|
        new_rev.patch_bytes(vma, [byte])
      end

      img = image(new_rev.ident)  # Image|PatchedImage associated with Address
      r.addresses.each do |addr|
        a = addr.dup
        a.image = img
        new_rev.add_address(addr.vma, a)
      end
    end

    # ----------------------------------------------------------------------
    # Addressess

=begin rdoc
Return Address object at VMA in the specified Revision (default: current).
=end
    def address(vma, rev=nil)
      addresses(rev||current_revision)[vma.to_i]
    end

=begin rdoc
Return a Hash [Integer -> Address] of Address objects that exist for the
specified VMA. The key is the revision in which the Address is defined. Note
that this performs an exact match for VMA; it does not check if VMA exists 
inside defined addresses. This method is generally used to prevent duplicate
Address objects from being created.
=end
    def addresses_for_vma(vma)
      @revisions.inject({}) do |h, rev|
        addr = rev.address(vma)
        h[rev.ident] = addr if addr
        h
      end
    end

=begin rdoc
Wrapper for ImageRevision#address_hash. This is used internally to obtain a
Hash of Address objects for lookup purposes (i.e. the Hash cannot be modified).

NOTE: This returns a Hash [Fixnum -> Address] of Address objects in the
specified revision. This does not return a list of all Addresses 'visible'
in ImageChangeset for the specified ImageRevision. To obtain such a list,
see AddressContainer#address_range.
=end
    def addresses(rev=nil)
      robj = revision(rev||current_revision)
      robj ? robj.address_hash : {}
    end

=begin rdoc
Define Address object at VMA in Map.
This does not check is the Address exists, or overlaps an existing Address.
=end
    def add_address(offset, vma, len, rev=nil)
      rev ||= current_revision
      raise "No such revision: #{rev}" if (! revision_exists? rev)
      add_address_object( Bgo::Address.new( nil, offset, len, vma ), rev )
    end

=begin rdoc
Add an Address object to a Revision.
This is used to add a pre-generated Address object (e.g. one created by a
disassembler) to the specified revision.
This does not check is the Address exists, or overlaps an existing Address.
=end
    def add_address_object(obj, rev=nil)
      obj.image = image_accessor(rev)
      revision(rev || current_revision).add_address(obj.vma, obj)
    end  

=begin rdoc
Remove Address object at VMA.
Note: this removes from the specified Revision (default: current).
=end
    def remove_address(vma, rev=nil)
      rev ||= current_revision
      revision(rev).remove_address(vma)
    end

    # ----------------------------------------------------------------------
    # Image
    
=begin rdoc
Patch bytes in current revision. This applies the bytes in the String 'bytes'
to the current revision starting at the specified VMA.
=end
    def patch_bytes(vma, bytes)
      rev = revision
      rev = add_revision if (not rev.patchable?)
      rev.patch_bytes(vma, bytes)
      rev 
    end

=begin rdoc
Return an Image object representing the contents of the ImageChangeset at the 
specified revision.
Note that this is an in-memory Image object generated on the fly *unless*
the revision is 0 (i.e. the base Image for the ImageChangeset).
=end
    def image(rev=nil)
      rev ||= current_revision
      return base_image if rev == 0
      @patched_image_cache[rev] ||= patched_image(rev)
    end

    # ----------------------------------------------------------------------
    def to_core_hash
      { 
        :image => @base_image.ident,
        :start_addr => @start_addr,
        :current_revision => @current_revision
      }
    end
      
    def to_hash
      to_core_hash.merge( { :revisions => @revisions.map { |r| r.to_hash } } )
    end
    alias :to_h :to_hash

    def fill_from_hash(h)
      (h[:revisions] || []).each do|rev_h|
        rev = ImageRevision.from_hash rev_h, @base_image
        import_revision(rev)
      end
      self.revision= h[:current_revision].to_i
      self
    end

    def self.from_hash(h, img)
      return nil if (! h) or (h.empty?)
      raise "Missing Bgo::Image in #{self.name}.from_hash" if ! img

      obj = self.new(img, h[:start_addr].to_i)
      obj.fill_from_hash h
    end

    # ======================================================================
    protected

=begin rdoc
Recursively apply patches to image starting at revision 1 and ending at
specified/current revision.
=end
    def patched_image(rev)
      PatchedImage.new(self, rev, start_addr)
      # NOTE: auto-comment was "Revision #{rev} image #{base_image.ident}"
    end

    def add_revision_object(obj)
      obj.modelitem_init_parent parent_modelitem if parent_modelitem
      @revisions << obj
      self.revision = obj.ident
      obj
    end

    def image_accessor(rev=nil)
      ImageAccessor.new(self, rev || current_revision)
    end

    # note: this wrapper is needed so that Git::ImageChangeset creates 
    #       Git::ImageRevisions
    def new_revision(ident, is_empty=false)
      ImageRevision.new(ident, is_empty)
    end

  end
end
