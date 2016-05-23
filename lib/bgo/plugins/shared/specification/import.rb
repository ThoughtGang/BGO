#!/usr/bin/env ruby                                                             
# :title: Bgo::Plugin::Specification::Import
=begin rdoc
Specification for importing data into BGO

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'tg/plugin'

require 'bgo/project'

module Bgo
  module Plugin
    module Spec

      # Import data into BGO from a File
      # Input: String, Bgo::Project, Hash of plugin-specific options
      # Output: Boolean
      TG::Plugin::Specification.new( :import, 
                                    'fn(Filename, Project, Hash)',
                                     [String, Bgo::Process, Hash], 
                                     [[TrueClass, FalseClass]]
                                    ) 
    end
  end
end
