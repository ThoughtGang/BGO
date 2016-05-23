#!/usr/bin/env ruby
=begin rdoc
BGO Tempfile helper methods

Copyright 2011 Thoughtgang <http://www.thoughtgang.org>
=end

require 'tempfile'

module Bgo

=begin rdoc
Return a TmpFile object with the contents of buf written to it. If a block is
passed, the TmpFile will be closed and deleted when the block exists, and
the return value is that of the block. If no block is given, the Tmpfile is
returned, and the caller is responsible for closing it.
=end
  def self.tmpfile_for_buffer(buf, pat, &block)
    # get a unique filename via Tempfile
    f = Tempfile.new(pat, :binmode => 'true')

    # write buffer to tmpfile
    f.write(buf)
    f.rewind

    if block_given?
      rv = yield f
      f.close
      #f.unlink # should be handled by GC
      f = nil
      GC.start
      rv
    else
      return f
    end
  end

end
