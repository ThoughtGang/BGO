#!/usr/bin/env ruby
# :title: Bgo::Plugin::Specification::Ident
=begin rdoc
Specification for file and data ident plugins

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'stringio'
require 'bgo/application/plugin'
require 'bgo/ident'

module Bgo
  module Plugin
    module Spec

      # Identify the type of file. Generally provided by Ident plugins.
      # Input: a string containing binary data or an IO object, and a
      #        path. Either can be empty; the plugin will decide whether
      #        to use the buffer, path, or both in doing the ident lookup.
      # Note: A StringIO will fail this test.
      # Output: an Ident object
      Bgo::Specification.new( :ident, 'fn(String|IO, String)',
                                     [[String, IO], String], [Bgo::Ident] 
                                    )
    end
  end
end
