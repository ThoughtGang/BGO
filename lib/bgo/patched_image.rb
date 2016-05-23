#!/usr/bin/env ruby                                                             
# :title: Bgo::PatchedImage
=begin rdoc
BGO Patched Image object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/image'

module Bgo

=begin rdoc
An in-memory representation of a Patched Image object. This associates a
base Image (or VirtualImage) object with an ImageChangeset and a Revision
number.
=end
  class PatchedImage < Image

    attr_reader :changeset
    attr_reader :revision
    attr_reader :start_addr

    IDENT_FMT = '%s(patchlevel-%d)'

    def initialize(changeset, revision, base_vma=0)
      @changeset = changeset
      @revision = revision || 0
      @start_addr = base_vma || 0
    end

    def ident
      IDENT_FMT % [@changeset.base_image.ident, @revision]
    end

=begin rdoc
Unmodified base Image object.
=end
    def base_image
      @changeset.base_image
    end

    def size
      @changeset.base_image.size
    end

=begin rdoc
Return contents as a String of bytes
=end
    def contents
      # Apply each revision to contents of base image
      buf = base_image.contents.dup
      @changeset.upto(@revision) do |rev|
        cb = rev.changed_bytes
        cb.keys.each { |vma| buf[vma_offset(vma)] = cb[vma] }
      end
      buf
    end

    def vma_offset(vma)
      addr = vma - start_addr
      (addr < 0 || addr >= size) ? nil : addr
    end

=begin rdoc
Construct Image from PatchedImage.
=end
    def to_image
      # TODO: generate Image object from PatchedImage contents
      raise NotImplementedError
    end

    def to_hash
      raise "PatchedImage should never be serialized!"
    end
    alias :to_h :to_hash

    def fill_from_hash(h, proj={})
      raise "PatchedImage should never be serialized!"
    end

    def self.from_hash(h, proj={})
      raise "PatchedImage should never be serialized!"
    end
  end
end
