#!/usr/bin/env ruby
# :title: MIME ident mixins
=begin rdoc
MIME ident.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

Code shared by plugins that operate on MIME types.
=end

module Bgo
  module Plugins
    module Ident

=begin rdoc
Methods and constants shared by plugins that operate MIME types.
=end
      module Mime

=begin rdoc
Return true if mime contains object code.
=end
        def self.code?(mime)
          # from /usr/share/file/magic.mime
          return true if mime == 'application/x-java-applet'
          return true if mime == 'application/x-object'
          return true if mime == 'application/x-executable'
          return true if mime == 'application/x-sharedlib'
          return true if mime == 'application/x-coredump'
          return true if mime == 'application/x-dosexec'
          # MIME-type used for unrecognized executables
          return true if mime == 'application/octet-stream'
          # default to data
          false
        end
      end

    end
  end
end
