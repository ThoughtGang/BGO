#!/usr/bin/env ruby
# :title: Magic ident mixins
=begin rdoc
Magic

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

Code shared by plugins that depend on Magic (libmagic or file utility).
These methods are used to parse libmagic output.
=end

require 'bgo/ident'
require 'bgo/plugins/shared/ident/mime'

module Bgo
  module Plugins
    module Ident

=begin rdoc
Methods and constants shared by plugins that depend on Magic (i.e. libmagic)
=end
      module Magic

=begin rdoc
Return true if ident string or MIME type indicates that the target contains
object code.
=end
        def self.code?(ident, mime)
          return false if ident =~ /data/
          return Mime.code?(mime) 
        end

=begin rdoc
Return the content type indicated by the ident string and MIME-type: code
or data.

See Bgo::Ident.
=end
        def self.content_type(ident, mime)
          (code?(ident, mime) ? Bgo::Ident::CONTENTS_CODE : 
                                Bgo::Ident::CONTENTS_DATA)
        end

=begin rdoc
Generate a Bgo::Ident object for the provided ident string and MIME type.
The ident string is assumed to have come from libmagic (directly or via the
file utility).
=end
        def self.generate_ident(ident, mime)
          format = (ident =~ /data/) ? nil : ident.split.first
          Bgo::Ident.new( content_type(ident, mime), ident.split(',').first, 
                          ident, mime, format )
        end

      end

    end
  end
end
