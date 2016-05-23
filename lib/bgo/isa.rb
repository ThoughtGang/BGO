#!/usr/bin/env ruby                                                             
# :title: Bgo::Isa
=begin rdoc
BGO ISA (Instruction Set Architecture) support

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

module Bgo

=begin rdoc
BGO ISA modules must extend this module.
=end
  module Isa

=begin rdoc
Exception indicating that an invalid architecture has been used.
=end
    class InvalidArchitectureError < RuntimeError; end

    @isa_modules = []

    def self.extended(mod)
      register_isa_module(mod)
    end

=begin rdoc
Register an ISA module with the Bgo::Isa abstract base class. This is used only
if the module does not or cannot extend Bgo::Isa itself.
=end
    def self.register_isa_module(mod)
      @isa_modules << mod
    end

=begin rdoc
The canonical name for this architecture.
Contains a symbol that uniquely identifies this ISA.

NOTE: This is an abstract base class definition of the constant which must
be overridden in modules that extend Bgo::Isa. The default value is :unknown.
=end
    CANON_ARCH = :unknown

=begin rdoc
Return CANON_ARCH if str is a recognized name for this architecture, otherwise
return nil.

NOTE: This is an abstract base class method which must be overridden in modules
that extend Bgo::Isa. The defaul implementation always returns nil.
=end
    def self.canon_arch(name)
      nil
    end

=begin rdoc
Return a list (Array of Symbols) of supported ISAs.
=end
    def self.supported
      @isa_modules.map { |mod| mod.const_get(:CANON_ARCH) }
    end

=begin rdoc
Return the CANON_ARCH symbol of the first ISA module that matches the specified 
name. Note that 'name' can be the ISA CANON_ARCH symbol or a string that is a 
recognized name for an architecture.

Example:
  These all return the symbol :x86_64 :
    Bgo::Plugins::Isa.match(:x86_64) 
    Bgo::Plugins::Isa.match('x86_64')
    Bgo::Plugins::Isa.match('x86-64')
    Bgo::Plugins::Isa.match('amd64')
=end
    def self.match(name)
      @isa_modules.map { |mod| mod.canon_arch(name.to_s) }.compact.first
    end

=begin rdoc
Return the ISA module for the specified architecture. Note that 'ident' is the
canon_arch of the ISA, as returned by Isa.match.

Example:
  Bgo::Plugins::Isa.arch_for_name(:x86_64) 
=end
    def self.isa_for_arch(ident)
      return nil if ! ident
      @isa_modules.select { |mod| mod.const_get(:CANON_ARCH) == ident }.first
    end

=begin rdoc
Return the ISA module for the specified architecture. Note that 'name' can
be the ISA CANON_ARCH symbol or a string that is a recognized name for an
architecture.

Example:
  These all return the ISA module Bgo::Plugins::Isa::X86_64 :
    Bgo::Plugins::Isa.arch_for_name(:x86_64) 
    Bgo::Plugins::Isa.arch_for_name('x86_64')
    Bgo::Plugins::Isa.arch_for_name('x86-64')
    Bgo::Plugins::Isa.arch_for_name('amd64')
=end
    def self.isa_for_arch_name(name)
      return nil if ! name
      isa_for_arch( match(name.to_s) )
    end

=begin rdoc
Decode an ASCII string to a Bgo Instruction object. This requires that
arch be a valid ISA module.

Note: This uses an ISA module to generate an Instruction object from an
assembly-language string produced by a disassembler. Use a plugin with
the :disassemble specification to perform the actual disassembly.
=end
    def self.decode(str, arch, syntax=nil)
      mod = isa_for_arch_name( arch )
      raise InvalidArchitectureError.new("'#{arch}' not supported") if ! mod
      decoder = mod.const_get(:Decoder)
      decoder.instruction(str, arch, syntax)
    end

  end
end
