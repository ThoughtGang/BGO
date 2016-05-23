#!/usr/bin/env ruby                                                             
# :title: Bgo::Plugin::Specification::LoadTarget
=begin rdoc
Specification for load-target plugins.

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>

This is an aggregate plugin which, given a Project and an Array of filenames,
loads the files into the Project and performs a series of analyses on them. 
These will often be methods provided by other plugins, e.g. :ident, :parse_file,
:load_file.

Note that no behavior is guaranteed by a load-target plugin; the binary files
could be added as TargetFiles, Packets, or Processes, or could be ignored
entirely. The user should always specify which plugin to use with :load_target,
and never rely on the default.
=end

require 'tg/plugin'

module Bgo
  module Plugin
    module Spec

      # Load targets into a Project. The actions taken are determined by the
      # plugin, and should be general (e.g. ident, parse, and load a 
      # TargetFile, or ident and parse a Packet.
      # Input: Bgo::Project, String|Array of Strings (file paths), 
      #        Hash of plugin-specific options
      # Output: Success (true) or failure (false)
      TG::Plugin::Specification.new( :load_target, 
                                    'fn(Project, String path|Array, Hash)',
                                     [Bgo::Project, [String, Array], Hash], 
                                     [ [TrueClass, FalseClass] ]
                                    ) 
    end
  end
end
