#!/usr/bin/env ruby                                                             
# :title: Bgo::Plugin::Specification::LoadFile
=begin rdoc
Specification for file loader plugins

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'tg/plugin'

require 'bgo/file'
require 'bgo/process'

module Bgo
  module Plugin
    module Spec

      # Create memory maps and such for a Process object based on a file or 
      # buffer format.
      # Input: Bgo::Process, Bgo::TargetFile, Hash of plugin-specific options
      # Output: Hash { :arch_info, :maps, :images, :symbols }
      # TODO: replace with Bgo::LoadResults object?
      # NOTE: load_file plugins should always invoke Process#add_map_reloc
      #       instead of Process#add_map, unless they want to do their own
      #       rebasing of overlapping Map objects.
      TG::Plugin::Specification.new( :load_file, 
                                    'fn(Process, TargetFile|Packet, Hash)',
                                     [Bgo::Process, 
                                     [Bgo::TargetFile, Bgo::Packet], Hash], 
                                     [Hash]
                                    ) 

      # Load and disassemble a Target.
      # This loads one or more object files into a Process, then performs 
      # a disassembly on all entrypoints and (function) symbols in the
      # Process. The manner in which this operation is performed is left
      # entirely up to the plugin -- no other Specs or plugins need be invoked.
      # This is generally provided by plugins for 3rd-party applications which
      # perform the entire load-parse-disassemble cycle themselves, such as
      # Metasm or IDA.
      # Input: Bgo::Process, Array of Bgo::TargetFile, 
      #        Hash of plugin-specific options
      # Output: Hash { :arch_info, :maps, :images, :symbols }
      # TODO: replace with Bgo::LoadResults object?
      TG::Plugin::Specification.new( :load_target, 
                                    'fn(Process, Array[TargetFile], Hash)',
                                     [Bgo::Process, Array, Hash], 
                                     [Hash]
                                    ) 
    end
  end
end
