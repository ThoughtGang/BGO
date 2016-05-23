#!/usr/bin/env ruby
# :title: Bgo::Scope
=begin rdoc

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/symbol'

# TODO: ScopeIdent
#       clear delete 
#       extend enumerable enumerators
#       find symbol by value
#       list symbols, recurse=false
#       list symbols of type, recurse=false
#       deserialization of parent (is this even needed?)
#       deserialization of child scope must set parent! (can be done in owner)

module Bgo

=begin rdoc
A collection of symbols defined in a Scope (generally a Block, occasionally a
Target).
=end
  class Scope
    include Enumerable

    class NameConflict < RuntimeError; end
    class UnresolvedSymbol < RuntimeError; end

    attr_reader :parent

    # TODO: pass ident of block/whatever
    def initialize(ident, parent=nil)
      @ident = ident
      @symtab = {} # key: name, value: symbol

      self.parent = parent
    end

=begin rdoc
Child scopes. This is used mainly for symbol table generation.
=end
    def children
      @children ||= []
    end

=begin rdoc
Set Parent of this scope. Note that this populates Scope#children of parent
Scope.
=end
    def parent=(scp)
      @parent = scp
      scp.children << self if scp
    end

=begin rdoc
Return level of nesting for this Scope.
Note that this is recursive calling Parent#nesting.
=end
    def nesting
      @parent ? @parent.nesting + 1 : 1
    end

=begin rdoc
Return list of symbols defined in this scope.
If recurse is true, all child scopes are included as well.
=end
    def symbols(names_only=false, recurse=false)
      symtab = recurse ? @children.map { |c| c.symbols(names_only, true)
                                       }.flatten : []
      names_only ? @symtab.keys.concat(symtab) : @symtab.values.concat(symtab)
    end

=begin rdoc
Return a list of all namespaces defined in this scope. 
If recurse is true, all child scopes are included as well.
=end
    def namespaces(recurse=false)
      symbols(false, recurse).map { |s| s.namespace }.sort.uniq
    end

=begin rdoc
Return number of symbols defined in this scope.
=end
    def num_symbols
      @symtab.keys.count
    end

=begin rdoc
Define a symbol for function 'name' at location 'value' in scope.
=end
    def define_func(name, value, namespace=nil)
      define(CodeSymbol.new name, value, namespace)
    end

=begin rdoc
Define a symbol for variable 'name' at location 'value' in scope.
=end
    def define_var(name, value, namespace=nil)
      define(DataSymbol.new name, value, namespace)
    end


=begin rdoc
Define a symbol for constant 'name' with value 'value' in scope.
=end
    def define_const(name, value, namespace=nil)
      define(ConstSymbol.new name, value, namespace)
    end


=begin rdoc
Define a Symbol in scope by passing in a Symbol object.
=end
    def define(sym)
      raise NameConflict if @symtab.include? sym.name
      #FIXME: handle namespace better
      @symtab[sym.fullname] = sym
    end

=begin rdoc
Resolve name to a Symbol object. This recurses to Parent#resolve if necessary.
=end
    def resolve(name)
      #FIXME: how to handle namespace
      @symtab[name] || (parent ? parent.resolve(name) : nil)
    end

=begin rdoc
Resolve name to a Symbol object, raising an UnresolvedSymbol error if the
symbol is not defined. This recurses to Parent#resolve if necessary.
=end
    def resolve!(name)
      raise UnresolvedSymbol if not resolve(name) 
    end

    def each(&block)
      @symtab.values.each(&block)
    end

    # ----------------------------------------------------------------------
    def to_s
      # TODO: something better
      @symtab.values.inspect
    end

    def inspect
      # TODO: something better
      'Scope: ' + @ident
    end

    def to_hash
      {
        :ident => @ident,
        :symtab => @symtab.values.map { |s| s.to_hash }
      }
    end
    alias :to_h :to_hash

    def fill_from_hash(h)
      (h[:symtab] || []).each { |hh| define( Symbol.from_hash hh ) }
      self
    end

    def self.from_hash(h, parent=nil)
      return nil if (! h) || (! h[:ident])
      # Note: parent is filled by caller (usually Block.from_hash)
      self.new(h[:ident].to_s, parent).fill_from_hash(h)
    end

  end
end
