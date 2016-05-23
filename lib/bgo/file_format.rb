#!/usr/bin/env ruby                                                             
# :title: Bgo::FileFormat
=begin rdoc
BGO File Format Registry

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

module Bgo

=begin rdoc
Registry of file formats.
This is mostly used to report supported file formats to the user.
=end
  module FileFormat

    # array of symbols
    @formats = []

=begin rdoc
Notify the File Format Registry that a file format is registered.
This takes an Array of String or Symbol arguments, generates a canonical name
for each, and adds them to the internal list of supported file formats.
NOTE: This does not associate each file format with a list of plugins that 
support it. Only a list of supported file format names is stored.
=end
    def self.supports(*args)
      args.each do |name|
        sym = canon_name(name)
        @formats << sym if (! @formats.include? sym)
      end
    end

=begin rdoc
Return an Array of Symbols representing the file formats supported by BGO 
plugins.
=end
    def self.supported
      @formats.dup
    end


=begin rdoc
Generate a canonical name for file format. This replaces all non-alphanumeric
characters with a single underscore.
=end
    def self.canon_name(name)
      name.to_s.downcase.gsub(/[^[:alnum:]]+/, '_').to_sym
    end

  end
end
