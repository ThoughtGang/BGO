#!/usr/bin/env ruby
# :title: Bgo::Symbol
=begin rdoc
BGO Symbol object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

# TODO: Enum object?
# Indexing: need to store by both name and value, e.g.
#    proc/symbol/address/name/$name/value, type :
#                        value/$value/$name : path to name
#Constant: proc/symbol/constant/...
#Alternate Implementation:
# Top-level (File|Section) Hash of names to Array of Block ident, Symbol pairs.

# TODO: value can be an operand, e.g. a register or an effective address
# TODO: each symbol should also have an AuthorComment

# FIXME: Verify a Symbl can be an AddressExpression
# FIXME: Remove JSON object?

require 'bgo/util/json'

module Bgo

=begin rdoc
A mapping from a name to a value. Generally the value is an address.

A value can be any serializable object, e.g. a Fixnum, a String, or an
Operand.

Note that when an object is defined for a scope, it is defined for all 
children of that scope -- so defining an operand like [rbp+8] may be misleading if a child block modifies rbp.
=end
  class Symbol
    extend JsonClass
    include JsonObject

=begin rdoc
Symbol name.
=end
    attr_reader :name

=begin rdoc
Namespace containing symbol name. This can be used for grouping enumerations
or for a general symbol namespace.
=end
    attr_reader :namespace

=begin rdoc
Symbol value.
=end
    attr_reader :value

=begin rdoc
Symbol type, e.g. func/var/constant/enum.
=end
    #attr_reader :type

=begin rdoc
User-supplied comment value. Note that this is per-symbol.
=end
#FIXME : obsolete?
    attr_accessor :comment

    def initialize(name, value, namespace=nil)
      @name = name
      @namespace = namespace
      @value = value
    end

    def fullname
      @namespace ?  @namespace + '::' + @name : @name
    end

=begin rdoc
Is this a Code location?
=end
    def code?; false; end
=begin rdoc
Is this a Data location?
=end
    def data?; false; end
=begin rdoc
Is this a symbolic Constant?
=end
    def constant?; false; end
=begin rdoc
Is this a File Header symbol?
=end
    def header?; false; end

    #def file?; false; end
    #def lineno?; false; end

=begin rdoc
Type of symbol. Used for de-serialization.
=end
    def type; :unknown; end

    # ----------------------------------------------------------------------
    def to_s
      [namespace, name].compact.join '::'
    end

    def inspect
      name + (":0x%X" % value)
    end

    def to_hash
      {
        :type => type,
        :name => @name,
        :namespace => @namespace,
        :value => @value,
        :comment => @comment
      }
    end
    alias :to_h :to_hash

    def fill_from_hash(h)
      # FIXME: this may be obsolete
      @comment = h[:comment].to_s
      self
    end

    def self.from_hash(h)
      # REFACTOR : this switch statement (and type method) is silly
      cls = self
      case h[:type]
      when :code
        cls = CodeSymbol
      when :data
        cls = DataSymbol
      when :constant
        cls = ConstSymbol
      when :header
        cls = HeaderSymbol
      end
      cls.new(h[:name].to_s, h[:value], h[:namespace].to_s).fill_from_hash(h)
    end

  end

# ===========================================================================
=begin rdoc
A function or code label. Generally an address in a Code segment.
=end
  class CodeSymbol < Symbol
    def code?; true; end
    def type; :code; end
  end

=begin rdoc
A variable or data value. Generally an address in a Data segment.
=end
  class DataSymbol < Symbol
    def data?; true; end
    def type; :data; end
  end

=begin rdoc
A Constant value or Enumeration. Generally a Number or String.
=end
  class ConstSymbol < Symbol
    def constant?; true; end
    def type; :constant; end
  end

=begin rdoc
A Symbol used in a file header (metadata), e.g. a Section name.
=end
  class HeaderSymbol < Symbol
    def header?; true; end
    def type; :header; end
  end

# ===========================================================================
=begin rdoc
Binding of a Symbol to an Address.
=end
  # FIXME: Implement
  class Binding
  end

end
