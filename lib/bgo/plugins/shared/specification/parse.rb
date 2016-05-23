#!/usr/bin/env ruby                                                             
# :title: Bgo::Plugin::Specification::ParseFile
=begin rdoc
Specification for file parser plugins

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

require 'tg/plugin'
require 'bgo/file'

module Bgo
  module Plugin
    module Spec

      # Create sections and such for a File object based on the file format.
      # Input: Bgo::TargetFile object and a Hash of plugin-specific options
      # Output: Hash { :arch_info, :sections, :symbols }
      # NOTE: This modifies the TargetFile input object by creating Sections
      #       and Symbols. The return value is used only to check the result.
      # TODO: replace return value with Bgo::ParseResults object?
      TG::Plugin::Specification.new( :parse_file, 'fn(TargetFile|Packet, Hash)',
                                     [[Bgo::TargetFile, Bgo::Packet], Hash], 
                                     [Hash] 
                                    )

    end
  end
end
