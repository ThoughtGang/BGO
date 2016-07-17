#!/usr/bin/env ruby                                                             
# :title: Bgo::Plugin::Specification::Unpack
=begin rdoc
Specification for unpacker plugins

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/plugin'

require 'bgo/image'

module Bgo
  module Plugin
    module Spec

      # Unpack an Image to a new Image object
      # Input: Bgo::Image, Hash of plugin-specific options
      # Output: Bgo::Image if successfully unpacked, or nil
      Bgo::Specification.new( :unpack, 'fn(Image, Hash)',
                                     [Bgo::Image, Hash],
                                     [ [Bgo::Image, NilClass] ]
                                    )
    end
  end
end
