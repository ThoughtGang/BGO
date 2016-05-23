#!/usr/bin/env ruby                                                             
# :title: Bgo::Block
=begin rdoc
A block is used to arbitrarily structure code. Each block has its own
scope.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

# ident can be built from parent (or container if parent is nil) ident by
# composing with /

# TODO: Interpretation/Reconstruction/etc member
#       This is a Hash [Symbol -> Array [String] ] of source code generated for
#       block. Symbol can be a plugin name or a target language (:llvm).
#       Array is an Array of Strings (tokens or lines).
#       When this is serialized, it gets its own subdir.
#       Serialization: include scope and child blocks in json (nest)

require 'bgo/scope'
require 'bgo/model_item'

module Bgo

=begin rdoc
A collection of related instructions.

Note: a function will be a list of blocks.

Note: This is NOT a "basic block". This is purely for descriptive purposes.
=end
  class Block
    extend Bgo::ModelItemClass
    include Bgo::ModelItemObject

    include Enumerable

    class InvalidContainer < RuntimeError; end
    class BoundsExceeded < RuntimeError; end
    class IncompatibleRevision < RuntimeError; end
    class Duplicate < RuntimeError; end
    class ChildOverlap < RuntimeError; end

    attr_reader :parent
    attr_reader :scope
    attr_reader :start_addr
    attr_reader :size
    # FIXME: verify this acts as expected
    attr_reader :revision # TODO: min, max revision instead?
    alias :rev :revision

    def self.path_elem
      'block'
    end

    def self.child_iterators
      [ :addresses, :blocks ]
    end

    def self.default_child
      :address
    end

    def initialize(vma, sz, parent=nil, rev=nil)
      # These defaults are kind of a hack, but they allow a 'global' object
      # without a true start VMA or size, such as a Process.
      @start_addr = vma || 0
      @size = sz
      @revision = rev
      @children = {}  # key : rev #, value: Array of Block objects
      @container = nil
      self.parent = parent

      # ensure sane initial state
      @children[@revision] ||= []
    end

    # TODO: way to do absolute block ident?
    def ident
      "%08X_%d@%d" % [@start_addr, (@size || 0), (@revision || 0)]
    end

    def parent=(blk)
      raise "Cannot set parent of Block with children" if has_children?
      @parent = blk
      @revision ||= blk.rev if blk
      @revision ||= 0
      @scope ||= Scope.new ident, ((blk && blk.scope) || nil)
    end

    def container
      @container || (@parent ? @parent.container : nil)
    end

    def container=(obj)
      raise "Cannot set container Block with children" if has_children?
      @container = obj
    end

    # ----------------------------------------------------------------------
    def start_addr=(vma)
      parent_check! vma, size, revision
      container_check! vma, size
      @start_addr = vma
    end

    def end_addr
      start_addr + size - 1
    end

    def size=(sz)
      parent_check! start_addr, sz, revision
      container_check! start_addr, sz
      @size = sz
    end

    # ----------------------------------------------------------------------
    def num_children
      @children.values.flatten.count
    end

    def has_children?
      num_children > 0
    end

    # TODO: add recurse option (default to true?) which will return all
    #       child blocks in lower revisions which do not overlap existing 
    #       blocks. 
    def children(rev=nil, recurse=false)
      rev ||= revision
      arr = @children[rev] || [] 
      return arr if (! recurse) || rev <= revision

      (rev - 1).downto(revision) do |i|
        @children[i].each do |b|
          arr << b if arr.select { |blk| blk.overlap? b }.count == 0
        end
      end
      arr.sort { |a,b| a.start_addr <=> b.start_addr }
    end
    alias :blocks :children

=begin rdoc
Instantiate block by ident.
=end
    def child(ident, rev=nil)
      children(rev).select { |blk| blk.ident == ident }.first
    end
    alias :block :child

    def child_containing(vma, rev=nil)
      children(rev).select { |blk| blk.contains? vma }.first
    end

    # nesting - max depth of children in rev
    def nesting(rev=nil)
      rev ||= revision
      children(rev).map { |c| 1 + c.nesting(rev) }.max || 0
    end

    def addresses(rev=nil)
      raise InvalidContainer if ! container
      container.address_range(start_addr, size, rev || revision, false)
    end

    def create_child(vma, sz, rev=nil)
      rev ||= revision
      check! vma, sz, rev
      add_child self.class.new(vma, sz, self, rev), rev
    end

=begin rdoc
Delete child containing vma
=end
    def delete(vma, rev=nil)
      blk = child_containing(vma, rev)
      return if ! blk
      @children[blk.revision].delete blk
    end

=begin rdoc
Remove all child Blocks. If rev is specified, only the Blocks in the specified
revision are deleted.
=end
    def clear(rev=nil)
      if rev
        @children[rev] = []
      else
        @children = {}
      end
    end

    # return true if block contains addr
    def contains?(vma)
      vma >= start_addr && vma < (start_addr + size)
    end

    # return true if blk overlaps this block
    def overlap?(blk)
      #  raise ChildOverlap if (blk.contains? start_addr) || 
      #                        (blk.contains? eaddr) ||
      #                        (addr < blk.start_addr && eaddr > blk.end_addr)
      blk.contains?(start_addr) || blk.contains?(end_addr) ||
      (start_addr < blk.start_addr && end_addr > blk.end_addr)
    end

=begin rdoc
Raise exception if address and size overlap another address in revision.
This enforces the following constraints:
  * rev >= block.revision
  * addr and sz do not ecompass entire block
  * addr + sz does not exceed block bounds
  * addr + sz does not exceed container bounds, if container exists
  * addr + sz does not overlap an existing child of this block
Note: if passed a block, this will call the block on every child Block object.
If the block returns false, the child Block is not checked for overlap.
=end
    def check!(vma, sz, rev=nil, &block)
      raise IncompatibleRevision if rev && rev < revision
      raise Duplicate if vma == start_addr && sz == size
      raise BoundsExceeded if (vma < start_addr) || \
                              (vma >= (start_addr + size)) || \
                              (vma + sz) > (start_addr + size)
      container_check! vma, sz

      # check for overlap with existing block
      evma = vma + sz - 1
      (@children[rev] || []).each do |blk|
        next if (block_given?) && (! yield blk)
        raise ChildOverlap if (blk.contains? vma) || 
                              (blk.contains? evma) ||
                              (vma < blk.start_addr && evma > blk.end_addr)
      end
    end

    def parent_check!(vma, sz, rev)
      return if ! @parent
      @parent.check!(vma, sz, rev) { |blk| blk != self }
    end

    def container_check!(vma, sz)
      return if ! @container
      # NOTE: Not all containers will have a start_addr or size. These are
      #       considered 'infinite', i.e. Blocks will always fit.
      c_addr = (@container.respond_to? :start_addr) ? @container.start_addr : 0
      c_size = (@container.respond_to? :size) ? @container.size : (vma + sz)
      
      raise BoundsExceeded if (vma < c_addr || (vma + sz) > (c_addr + c_size))
    end

    def max_revision
      @children.keys.max || revision
    end

    # ----------------------------------------------------------------------
    def each(&block)
      # TODO: recurse = true
      children(max_revision).each(&block)
    end

    # iterate over each revision (yields array of Block)
    def each_revision(&block)
      @children.values.each(&block)
    end

    # iterate over each block in specific revision
    def each_in_revision(rev, &block)
      @children[rev].each(&block)
    end

    # iterate over each block in every revision
    # starts from lowest revision to highest
    def each_with_revision(&block)
      @children.each { |rev, arr| arr.each { |b| yield rev, b }  }
    end

    # TODO: better iterators

    # ----------------------------------------------------------------------
    # BASIC BLOCKS
    # FIXME: specify plugin? Metasm will want to generate its own basic blocks
    def basic_blocks(force_regen=false)
      return nil if ! verify_address_container

      # FIXME: container must be an AddressContainer (respond to address?)
      #
      @basic_blocks ||= {} # cached basic blocks
      # TODO: implement
      # foreach code address, order by addr, group by contiguous
      # * check parents for basic blocks
      # * check children for basic blocks
      @basic_blocks.dup
    end
    # TODO: interface to add basic blocks?
    # def basic_blocks=(h)

    # ----------------------------------------------------------------------
=begin rdoc
Analyze Block using a Plugin supporting the :analysis interface. The 'plugin' 
argument is the Plugin name, or nil to use the highest-rated Plugin. This
returns an AnalysisResults object (the output of the :analysis interface), or
false if no suitable plugin could be found.
Note: This will raise a NameError if PluginManager has not been started.
=end
    def analyze(plugin=nil, opts={}) 
      begin
        args = [self, opts]
        PluginManager.invoke_spec( :analysis, plugin, *args ) 
      rescue PluginManager::NoSuitablePluginError 
        false
      end
    end

=begin rdoc
Invoke Block#analyze and store the results in the Block#analysis Hash.
=end
    def analyze!(plugin=nil, opts={})
      results = analyze(plugin, opts)
      @analysis ||= {}
      @analysis[results.ident] = results if results
    end

=begin rdoc
Return the analysis results Hash for this Block.
=end
    def analysis
      @analysis || {}
    end

    # ----------------------------------------------------------------------

    def to_hash
       {
         :start_addr => @start_addr,
         :size => @size,
         :scope => @scope.to_hash,
         :revision => @revision,
         :children => @children.values.flatten.map { |c| c.to_hash }
         # TODO: basic blocks
       }
    end
    alias :to_h :to_hash

    def fill_from_hash(h)
      p_scope = @parent ? @parent.scope : nil
      @scope = Scope.from_hash(h[:scope], p_scope)

      (h[:children] ||[]).each do |hh|
        obj = self.class.from_hash(hh, self)
        add_child obj, obj.rev
      end
       # TODO: basic blocks
      self
    end

    def self.from_hash(h, parent=nil)
      return nil if (! h) || (h.empty?)
      self.new(h[:start_addr].to_i, h[:size].to_i, parent, h[:revision].to_i
              ).fill_from_hash(h)
    end

    protected
    def check_overlap_in_parent
      return if ! parent

      parent.children(revision).each do |blk|
        raise ChildOverlap if (blk.overlap? self) || (self.overlap? blk)
      end
    end

    def add_child(obj, rev)
      @children[rev] ||= []
      @children[rev] << obj
      obj
    end

    private
    def verify_address_container
      # FIXME: check AddressContainer methods
      #$stderr.puts "Block.container #{@container.class.name} ! AddressContainer"
      @container
    end
  end

=begin rdoc
A basic block
=end
  #FIXME: must be tied to a revision -- but so is a block.
  class BasicBlock
    attr_reader :start_addr
    attr_reader :end_addr
    attr_reader :parent # parent block: used to get addresses
    attr_reader :rev    # revision #, if applicable
    # TODO: references to, from
  end

end
