#!/usr/bin/env ruby
# Copyright 2011 Thoughtgang <http://www.thoughtgang.org>
# Unit test for developing BGO api ADDITIONS

# TODO: In order of importance...
#   * block
#   * symbol
#   * changeset container
#   * datatype
#   * string dt
#   * record dt
#   * class dt
#   * symbol hint

require 'test/unit'

# Global BGO objects to test on
require 'bgo/project'
require 'bgo/image'
require 'bgo/map'

require 'bgo/address'

module Bgo
  # in binaries, the purpose of the sym tab is different. here, we want to
  # know the possible symbols for a value, not the value of a symbol. in fact,
  # symbols are used for display purposes only -- as annotations.
  #
  # symbol hint in address objects: operand, record field, array element,
  # value. symbol hint object in address. array of hints. each hint is a
  # name/value + a ruby sym specifying what the symbol is applied to:
  #   :dest :src :target :displacement :immediate :operand_n :field_n :byte
  # ...prob sym (ident) + an optional arg, e.g :element, n
  # Basically, a Hash of hints.
  # Address.symbol_hint = { :operand => { :1 => , :src => }, :pointer => }
  # Datatype instances are stored, like ISA instructions, as a single instance.
  #
  # value, symbol, scope
  # Address
  #   << symbols
  # end
  # Process/Section
  #   << blocks
  # end

# ===========================================================================
# BLOCK
  class Block
=begin rdoc
Block object that contains this block. This is nil if the Block is top-level.
=end
    attr_accessor :parent
=begin rdoc
File or Process object containing this Block. This is never nil.
Note: the container is used to access the symbol table.
=end
    attr_reader :container
=begin rdoc
Start address
=end
    attr_reader :start_addr
=begin rdoc
Size of block in bytes
=end
    attr_reader :size

=begin rdoc
The minimum changeset in container to which this Block applies. If nil, then
Block applies to all changesets from 0 to @max_cs.
=end
    attr_reader :min_cs
=begin rdoc
The maximum changeset in container to which this Block applies. If nil, then
Block applies to all changesets from @min_cs to container.changesets.count().
=end
    attr_reader :max_cs

    def initialize(container,start,size,parent=nil)
      @children = []
      @container = container
      @start_addr = start
      @size = size
      parent.add(self) if parent
      #@parent = parent
    end

=begin rdoc
Array of Block objects that are direct children of this Block. Array is empty
if there are no children.

Note: no block that is a child of this block can extend past its bounds.
=end
    def children
      @children.sort_by { |blk| blk.start_addr }
    end

=begin rdoc
=end
    def ==(other)
      (container == other.container && parent == other.parent && 
       start_addr == other.start_addr && size == other.size) ? true : false
    end

=begin rdoc
Return true if 'other' (a Block object) is a child of the block.
=end
    def contain?(other)
      return true if children.include? other
      (children.select { |b| b.contain? other }.count > 0)
    end

=begin rdoc
Return true if Block includes address (a Fixnum or an Address object). 
If 'addr' is an Address object, its contents must lie entirely inside the
address space defined by the block.
=end
    def include?(addr)
      max_addr = start_addr + size

      (addr.kind_of? Address) ? \
        addr.vma >= start_addr && (addr.vma + addr.size) <= max_addr : \
        addr >= start_addr && addr < max_addr
    end

=begin rdoc
Return true if provided Block overlaps this block -- that is, if they have any
addresses in common.
=end
    def overlap?(blk)
      include?(blk.start_addr) || include?(blk.start_addr + blk.size - 1)
    end

=begin rdoc
Return the block occuring before the current block in the parent
=end
    def prev(other)
      return nil if not parent
      parent.children.select { |b| (b.start_addr + b.size) <= start_addr }.first
    end

=begin rdoc
Return the block occuring after the current block in the parent
=end
    def next(other)
      return nil if not parent
      parent.children.select { |b| b.start_addr >= (start_addr + size) }.first
    end

    def add(blk)
      # TODO: RangeError
      raise "Oh Crap" if (not overlap? blk)

      @children.each do |c|
        # TODO: OverlapError
        raise "Crap Crap" if (c.overlap? blk)
      end
      blk.parent = self
      @children << blk
    end

=begin rdoc
Return a list of basic blocks for this block.

Note: this ignores the presence of child blocks.
=end
    def basic_blocks
      # TODO
    end

=begin rdoc
Should this be a block or an Address? Also with first-next-last.
=end
    def []
    end
  end

  # ----------------------------------------------------------------------
=begin rdoc
=end
  class BasicBlock < Block
    # TODO: entrance Addr
    #       exit Addr []. call: [tgt, next]; jmp [tgt]; jcc [tgt, next], ret: []
    #       NOTE: next is different from successor!
    # ctor start, end = Address or vma?
    def initialize()
    end

    def children
      []
    end

    # successor, predecessor -- aliases?
  end

  # ----------------------------------------------------------------------
=begin rdoc
Children of CompoundBlock are Block object (or descendants such as BasicBlock
or CompoundBlock objects), not necessarily contiguous.
=end
  class CompoundBlock < Block

    def start_addr
      #children.first.start_addr
    end

    def end_addr
      #children.last.end_addr
    end

=begin rdoc
Largest # of contiguous bytes that will contain both strt_addr and end_addr.

Use num_bytes or count to get number of bytes in all blocks, summed.
=end
    def size
      #end_addr - start_addr
      # count/num_bytes:
      #   children.inject(0) { |c, sum| sum += c.size; sum }
    end
  end

=begin rdoc
A compound block with ret-type, args, symbol.
Or is it a typedef associated with a compound block?
TODO.
=end
  def Function
  end

# ===========================================================================
# SYMBOL
=begin rdoc
=end
  class Symbol
=begin rdoc
Name or label of symbol.
Note: namespaces are implicit, by using '::' in names
=end
    attr_reader :name
=begin rdoc
Value of symbol
=end
    attr_reader :value
=begin rdoc
Block object in which symbol is valid, or nil if symbol is global.
=end
    attr_reader :scope
=begin rdoc
A nil scope attribute impliesd global (container) scope.
Note: a reference to container is not necessary as symbols will be used
within a Block context.
=end
    GLOBAL = nil
=begin rdoc
Type of symbol
=end
    attr_reader :type
=begin rdoc
Symbolic constant (e.g. 0 = 'STDIN', 1 = 'STDOUT', etc)
=end
    CONSTANT = :constant
=begin rdoc
A data variable
=end
    VARIABLE = :variable
=begin rdoc
A function, usually exported or part of an internal API
=end
    FUNCTION = :function
=begin rdoc
An arbitrary code label, e.g. via setjmp
=end
    LABEL = :label
=begin rdoc
Type of symbol. Default type is VARIABLE.
=end
    TYPES = [ CONSTANT, VARIABLE, FUNCTION, LABEL ]

=begin rdoc
=end
    def initialize(name, value, type=VARIABLE, scope=nil)
      @name = name
      @value = value
      @type = type
      @scope = scope
    end

=begin rdoc
Return true if symbol is global.
=end
    def global?
      scope == GLOBAL
    end

=begin rdoc
Return true if a symbol is local (i.e. NOT global).
=end
    def local?
      scope != GLOBAL
    end

=begin rdoc
Return true if symbol is defined under the specified scope.

A symbol is defined if its scope is global, or if the specified scope is a child
of the symbol's scope.
=end
    def defined_in?(a_scope)
      return true if not scope
      (scope == a_scope || (scope.contain? a_scope))
    end
  end

  # ----------------------------------------------------------------------
=begin rdoc
=end
  class SymbolTree
  end

# ===========================================================================
# CHANGESET CONTAINER
  
# ===========================================================================
=begin rdoc
A type definition for a DefinedData instance.

All classes derived from Datatype represent type categories, e.g. Integer,
String, Array, etc. Instances of Datatype-derived classes represent actual
datatypes, e.g. UnsignedInteger32, AsciiString, UnicodeString, IntegerArray.

The Datatype class maintains a registry of available datatypes; it is important
that all derived classes call the Datatype constructor.

Examples:

===Derived Classes
Classes derived from Datatype are either abstract or concrete, depending on
whether the class represents a fully-defined type category.

All concrete classes must implement the following methods:

  self.factory
  self.apply/unpack?

TODO: sort out terminaology here
A fully-defined type definition has a final size in bytes.
In terms of arrays, an array with an UNKNOWN size should be given the
minimum known size. All pointers, therefore, are an array of size 1.
This can be updated during analysis by changing the type instance of
the DefinedData.
=end
  class Datatype

    # TODO: operations on types themselves, e.g. intersection/union of
    #       values? perhaps only for Integer types?
    # TODO: how to generate value and range of values

=begin rdoc
Hash (name -> instance) containing all available datatypes.
=end
    @@registry = {}

=begin rdoc
Name of the type definition.
=end
    attr_reader :name

=begin rdoc
Size of the type in bytes.
=end
    attr_reader :size

    def initialize(name, size)
      @name = name
      @size = size
      # add to registry
      @@registry[name] = self
    end

=begin rdoc
Return all type definition names, in lexical order.
=end
    def self.names
      @@registry.keys.sort
    end

=begin rdoc
Return an Array of all Datatype class instances, organized by name.
=end
    def self.types
      @@registry.values.srt_by { |t| t.name }
    end

=begin rdoc
Return Datatype class instance for 'name'.
=end
    def self.lookup(name)
      @@registry[name]
    end

=begin rdoc
Apply datatype to binary String 'str'. 

This returns a Hash with the following elements:

  :datatype : Name of datatype as returned by self.name (NOT class name)
  :value    : Value object as returned by self.value
=end
    def apply(str)
      { :datatype => name, :value => value }
    end

=begin rdoc
Return a Ruby object representing the value of the binary string 'str'
converted to this datatype.

The return value will be one of the following:

  Fixnum - For integer values
  Float  - For floating point values
  String - For ASCII and Unicode strings
  Array  - Array of ruby objects
  Hash   - Composite objects

Classes derived from Datatype *must* override this method. The default
implementation returns an array of Fixnums, representing the raw bytes in
'str'.

NOTE: 'endian' parameter is a placeholder, pending design decisions on
      how endian conversion will be handled in the data model.   
=end
    def value(str, endian=false)
      str.bytes.to_a
    end

  end

  # ----------------------------------------------------------------------
=begin rdoc
An alias for an existing type.

This can be used to emulate typedef.
=end
  class AliasType < Datatype
    # TODO: delegate all operations to dtype object.
    def initialize(name, dtype)
    end
  end

  # ----------------------------------------------------------------------
=begin rdoc
Primitive type for integers of any size or signedness.

Instances of this type have the name [u]int(size * 8), e.g.:
  uint32 : IntegerType.new(4, true)
  int8   : IntegerType.new(1)
=end
  class IntegerType < Datatype

=begin rdoc
Is integer unsigned?
=end
    attr_reader :signed

    def initialize(size, signed=false)
      @signed = signed
      super self.class.name(size, signed)
    end

    def self.name(size, signed=false)
      "#{signed ? '' : 'u'}int#{size*8}"
    end

    def self.factory(size, signed=false)
      obj = Datatype.lookup(name(size, signed))
      obj ? obj : new(size, signed)
    end
  end

  # ----------------------------------------------------------------------
=begin rdoc
Primitive type for floating-point numbers of any size.

Instances of this type have the name float(size * 8), e.g.:
  float8 : FloatType.new(1)
  float80 : FloatType.new(10)
=end
  class FloatType < Datatype
    def initialize(size)
      super self.class.name(size)
    end

    def self.name(size)
      "#float#{size*8}"
    end

    def self.factory(size)
      obj = Datatype.lookup(name(size))
      obj ? obj : new(size)
    end
  end

  # ----------------------------------------------------------------------
=begin rdoc
A single character, of any character set.
# TODO
# Ascii as one type, unicode as another? wstr?
=end
  class CharacterType < Datatype
    def charset
    end
  end

  # ----------------------------------------------------------------------
=begin rdoc
A single ASCII character
# TODO
=end
  class CCharType < CharacterType
  end

  # ----------------------------------------------------------------------
=begin rdoc
An array of same-typed objects.

# TODO
=end
  class ArrayType < Datatype

=begin rdoc
The type of element contained in the array.
=end
    attr_reader :base_type

    def initialize(base_type, len=nil)
      super self.class.name(base_type, len), (base_type.size * len)
    end

    def self.name(base_type, len)
      "#{base_type.name}[#{len ? len : ''}]"
    end

    def self.factory(base_type, len)
      obj = Datatype.lookup(name(base_type, len))
      obj ? obj : new(base_type, len)
    end
  end

  # ----------------------------------------------------------------------
=begin rdoc
# TODO
can be applied to strings of any length.
this means array type may not be suitable, even though this *acts* as an
array of Character terminators.
header (e.g. len), terminator
=end
  # Note: String typedef classes will be instances of StringType classes.
  class StringType < Datatype
  end

  # ----------------------------------------------------------------------
=begin rdoc
ASCII string, null-terminated. length must be nil. Size must be overridden.
# TODO
=end
  class CStringType < StringType
    # of CChar
  end

  # ----------------------------------------------------------------------
=begin rdoc
# TODO
[types], [names]
cast uses dict (like record) to convert name to type
=end
  class UnionType < Datatype
    # not sure... cast_as() ? default_type?
    # array of alternatoves, defaults to first
  end

  # ----------------------------------------------------------------------
=begin rdoc
# TODO
=end
  class ReferenceType < Datatype
    # pointer to basetype
  end

  # ----------------------------------------------------------------------
=begin rdoc
A classic C pointer.

This is implemented as a union of a Reference(basetype) and an 
Array(basetype, 1) -- that is, it acts as both a memory reference and a
single-element array.

# TODO
=end
  class PointerType < Datatype
    # NOTE: pointer to string when ! static string len, ditto for array.
  end

  # ----------------------------------------------------------------------
=begin rdoc
# TODO
=end
  # instances of recordtype are record typdefs etc
  class RecordType < Datatype
    # TODO: alignment
    #       size must take into account alignment!
    #
    # List of Types in record. List of names, internal to Record, for each
    # Type
    # [CStringType instance, Integer32Type instance, 
    # Integer32ArrayType instance]

=begin rdoc
Array of datatypes for each record field/member/element.
=end
    attr_reader :elements
=begin rdoc
Hash (name -> index) of record field/member/element names.
=end
    attr_reader :index

    def initialize( names, types, align=1 )
      @index = {}
      @elements = []
      types.each_with_index do |t, idx|
        @elements << t
        @index[names[idx]] = @elements.count - 1
        # TODO: if align, add fake element
      end
    end
  end

  # ----------------------------------------------------------------------
=begin rdoc
# TODO
=end
  class ClassType < RecordType
    # Record type + vtable
  end

  # ----------------------------------------------------------------------
=begin rdoc
An occurence of a Datatype in memory. This is the equivalent of an Instruction
object for Address objects whose contents are data, not code.

Note that an Address object whose content-type is DATA can have either a
DefinedData object for its contents, or nil -- in which case the contents
are the raw bytes.
=end
  class DefinedData

    # instance of Datatype
=begin rdoc
The datatype (or type definition) for this data. This is an instance of a 
Datatype class.

to_json: { :type => typename, :value => ??? }
=end
    attr_reader :datatype

    def initialize(dtype)
      @datatype = dtype
    end

    # TODO: unpack? apply?
  end
end

# ===========================================================================
# UT

class TC_ApiDecTest < Test::Unit::TestCase
  PROJECT = Bgo::Project.new()
  IMG_BUF = "\x00\x00\x00\x00\xCC\xCC\xCC\xCC\xFF\xFF\xEE\xEE\xDD\xDD\xBB\xBB" +
            "\x11\x22\x33\x44\x55\x66\x77\x88\x99\xAA\xBB\xCC\xDD\xEE\xFF\x00" +
            "\x10\x20\x30\x40\x50\x60\x70\x80\x90\xA0\xB0\xC0\xD0\xE0\xF0\x00" +
            "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F\x00"
  IMAGE = Bgo::Image.new(IMG_BUF)
  MAP_VMA = 0x8040100
  MAP_OFF = 16
  MAP_SIZE = 32
  AI = Bgo::ArchInfo.new('i386', 'x86-64', Bgo::ArchInfo::ENDIAN_LITTLE)
  MAP = Bgo::Map.new(MAP_VMA, IMAGE, MAP_OFF, MAP_SIZE, 
                     [Bgo::Map::FLAG_READ, Bgo::Map::FLAG_EXEC], AI)

  def setup
    # verify that everything got built correctly
    assert( PROJECT )
    assert( IMAGE )
    assert( AI )
    assert( MAP )
  end

  def test_block_api
    # TODO: move this into Map.new (if blocks.count==0) or Map.create
    top_block = Bgo::Block.new(MAP, MAP.start_addr, MAP.size)
    assert_equal(MAP, top_block.container)
    assert_equal(MAP.start_addr, top_block.start_addr)
    assert_equal(MAP.size, top_block.size)
    assert_equal(0, top_block.children.count)
    assert((not top_block.min_cs))
    assert((not top_block.max_cs))

    tmp_block = Bgo::Block.new(MAP, MAP.start_addr, MAP.size)
    assert(top_block == tmp_block)
    assert(top_block.overlap? tmp_block)

    a_blk = Bgo::Block.new(MAP, MAP.start_addr, 8, top_block)
    assert_equal(1, top_block.children.count)

    b_blk = Bgo::Block.new(MAP, MAP.start_addr+8, 16)
    top_block.add(b_blk)
    # TODO: <<
    assert_equal(2, top_block.children.count)

    dup_blk = Bgo::Block.new(MAP, MAP.start_addr, 8)
    assert_raises(RuntimeError) { top_block.add(dup_blk) }
    assert_raises(RuntimeError) { b_blk.add(dup_blk) }

    # contain? include? prev next
    # basic_blocks []

    # TODO:
    # create addresses
    # basic block
    # compound block
    # scope?
  end

  def test_symbol_api
  end

  def test_cs_container_api
  end

  def test_dtype_api
  end
end

