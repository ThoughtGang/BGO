#!/usr/bin/env ruby
# :title: Bgo::Reference
=begin rdoc
BGO Reference object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

# TODO: How to handle Fixups, Dependencies

require 'bgo/util/json'

module Bgo


# ----------------------------------------------------------------------
=begin rdoc
A 'from' or 'to' item in a Reference.
This is a base class.
=end
  class RefItem
    extend JsonClass
    include JsonObject

    UNBOUND = '?'   # value of unbound RefItem

    attr_reader :value

    def initialize(value)
      @value = value
    end

    def address?; false; end
    alias :addr? :address?

    def function?; false; end
    alias :func? :function?

    def file?; false; end

    def library?; false; end
    alias :lib? :library?

    def process?; false; end

    def thread?; false; end

    def uri?; false; end
    alias :url? :uri?

    def type; :unknown; end

    def bound?
      @value.to_s != UNBOUND
    end

    def to_s
      @value.to_s
    end

    def to_hash
      { :type => type, :value => value }
    end
    alias :to_h :to_hash

    def self.from_hash(h)
      return nil if (! h) or (h.empty?)

      # REFACTOR : this switch statement (and type method) suck!
      cls = self
      case h[:type]
      when :address
        cls = AddrRef
      when :function
        cls = FuncRef
      when :file
        cls = FileRef
      when :library
        cls = LibRef
      when :process
        cls = ProcessRef
      when :uri
        cls = UriRef
      end
      cls.new h[:value]
    end
  end

=begin rdoc
An Address reference. This is the value of an address, or an object pathspec.
=end
  class AddrRef < RefItem
    # TODO: initialize(value) for value check?
    def address?; true; end
    def type; :address; end
    def to_s; "%08X" % @value; end
  end

=begin rdoc
A Function reference. This is the name of a function, or an object pathspec.
=end
  class FuncRef < RefItem
    # TODO: initialize(value) for value check?
    def function?; true; end
    def type; :function; end
  end

=begin rdoc
A File reference. This is the name/path of a file, or an object pathspec.
=end
  class FileRef < RefItem
    # TODO: initialize(value) for value check?
    def file?; true; end
    def type; :file; end
  end

=begin rdoc
A (shared) library reference. This is the name of a library
=end
  class LibRef < RefItem
    # TODO: initialize(value) for value check?
    def library?; true; end
    def type; :library; end
  end

=begin rdoc
A process reference. This is the ident of a process, or an object pathspec.
=end
  class ProcessRef < RefItem
    # TODO: initialize(value) for value check?
    def process?; true; end
    def type; :process; end
  end

=begin rdoc
A thread reference. This is the ident of a thread, or an object pathspec.
  class ThreadRef < RefItem
    # TODO: initialize(value) for value check?
    def thread?; true; end
  end
=end

=begin rdoc
A reference to a URI (e.g. through a socket). This is a String.
=end
  class UriRef < RefItem
    # TODO: initialize(value) for value check?
    def uri?; true; end
    def type; :uri; end
  end

  # ===================================================================
=begin rdoc
A reference from one object to another. Generally objects are of the same type.

This is a base class for all reference types.
=end
  class Reference
    extend JsonClass
    include JsonObject

    # TODO: better access methods, e.g. file/url/process access
    ACCESS_R = :read
    ACCESS_W = :write
    ACCESS_X = :exec

=begin rdoc
The 'from' RefItem, or the referrer.
=end
    attr_reader :from
=begin rdoc
The 'to' Refitem, or the referent.
=end
    attr_reader :to
=begin rdoc
The type access performed by 'from' on 'to': read, write, exec, etc.
=end
    attr_reader :access
=begin rdoc
Revision in changeset
=end
    attr_reader :revision

    REF_UNKNOWN = RefItem.new('unknown')

    def initialize(from_item, to_item, access=ACCESS_R, rev=nil)
      @from = from_item
      @to = to_item
      @access = access || ACCESS_R
      @revision = rev
    end

    def to_s
      "#{from} -> #{to}"
    end

    def to_hash
      {
        :from => @from.to_hash,
        :to => @to.to_hash,
        :access => @access,
        :revision => @revision
      }
    end
    alias :to_h :to_hash

    def self.from_hash(h)
      return nil if (! h) or (h.empty?)
      from_obj = RefItem.from_hash h[:from]
      to_obj = RefItem.from_hash h[:to]
      return nil if (! from_obj) or (! to_obj)
      access = h[:access] ? h[:access].to_sym : nil
      rev = h[:revision] ? h[:revision].to_i : nil
      self.new from_obj, to_obj, access, rev
    end

    def self.addr_to_addr(from_vma, to_vma, access, rev=nil)
      self.new( AddrRef.new(from_vma), AddrRef.new(to_vma), access, rev )
    end

    def self.addr_to_func(from_vma, to_func, access, rev=nil)
      self.new( AddrRef.new(from_vma), FuncRef.new(to_func), access, rev )
    end

    #def self.addr_to_fixup(from_vma, to_func, access, rev=nil)
    #end

    def self.addr_to_file(from_vma, to_path, access, rev=nil)
      self.new( AddrRef.new(from_vma), FileRef.new(to_path), access, rev )
    end

    def self.addr_to_proc(from_vma, to_ident, access, rev=nil)
      self.new( AddrRef.new(from_vma), ProcRef.new(to_ident), access, rev )
    end

    def self.addr_to_uri(from_vma, to_uri, access, rev=nil)
      self.new( AddrRef.new(from_vma), UriRef.new(to_uri), access, rev )
    end
  end

  # ===================================================================
=begin rdoc
A collection of References object, generally associated with a Target object.
=end
  class References
    # @from_index is a Hash[VMA -> Array] of from-value to Array of References
    # @to_index is a Hash[VMA -> Array] of to-value to Array of References
    def initialize
      clear!
    end

=begin rdoc
Add Reference object to References collextion
=end
    def <<(ref)
      @from_index[ref.from.value] ||= []
      @from_index[ref.from.value] << ref

      @to_index[ref.to.value] ||= []
      @to_index[ref.to.value] << ref
    end

=begin rdoc
Return an Array of all references from 'val'.
Note that 'val' can be a RefItem, or the value of a RefItem.
=end
    def from(val)
      @from_index[refitem_or_value val] || []
    end

=begin rdoc
Return an Array of all references to 'val'.
Note that 'val' can be a RefItem, or the value of a RefItem.
=end
    def to(val)
      @to_index[refitem_or_value val]
    end

=begin rdoc
Remove reference from 'from_val' to 'to_val'.
Note that these can be a RefItem objects, or the values of RefItem objects.
=end
    def remove(from_val, to_val)
      fval = refitem_or_value from_val
      tval = refitem_or_value to_val
      (@from_index[fval] || []).reject! { |r| r.to.value == tval }
      (@to_index[tval] || []).reject! { |r| r.from.value == fval }
    end

=begin rdoc
Clear all References from collection.
=end
    def clear!
      @from_index = {}
      @to_index = {}
    end

=begin rdoc
Remove all references from 'val'.
Note that 'val' can be a RefItem, or the value of a RefItem.
=end
    def clear_from(val)
      fval = refitem_or_value val
      @from_index.delete fval
      @to_index.each { |k, arr| arr.reject! { |r| r.from_value == fval } }
    end

=begin rdoc
Remove all references to 'val'.
Note that 'val' can be a RefItem, or the value of a RefItem.
=end
    def clear_to(val)
      tval = refitem_or_value val
      @to_index.delete tval
      @from_index.each { |k, arr| arr.reject! { |r| r.to_value == tval } }
    end

    def to_hash
      { :refs => @to_index.map { |k, arr| arr.map { |r| r.to_hash } }.flatten }
    end
    alias :to_h :to_hash

    def fill_from_hash(h)
      return self if ! h
      (h[:refs] || []).each { |hh| self << Reference.from_hash(hh) }
      self
    end

    def self.from_hash(h)
      obj = self.new
      obj.fill_from_hash h
    end

    private

    def refitem_or_value(obj)
      (obj.kind_of? RefItem) ? obj.value : obj
    end
  end

end
