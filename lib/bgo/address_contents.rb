#!/usr/bin/env ruby
# :title: Bgo::AddressContents
=begin rdoc
BGO AddressContents base class

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

module Bgo

=begin rdoc
Base class for contents of Address objects, e.g. Instruction.
=end
  class AddressContents
    @@content_types = {}

    def self.register_content_type(sym)
      @@content_types[sym.to_sym] = self
    end

    # ----------------------------------------------------------------------
    # FIXME: are these needd?
    def to_hash
      {}
    end
    alias :to_h :to_hash

    def fill_from_hash(h)
      self
    end

    def self.from_hash(h)
      return nil if (! h) || (h.empty?)
      type = h[:content_type]
      data = h[:contents]
      return nil if (! type) || (! data)
      cls = @@content_types[type.to_sym]
      cls ? cls.from_hash(data) : nil
    end

  end
end
