#!/usr/bin/env ruby                                                             
# :title: Bgo::Plugin::Specification::Export
=begin rdoc
Specification for exporting BGO data to a file

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/plugin'

require 'bgo/project'

module Bgo
  module Plugin
    module Spec

      # Create a file with exported BGO data.
      # Note: Hash[:objects] can be used to pass in specific object paths
      #       to instantiate and serialize.
      # Input: String, Bgo::Project, Hash of plugin-specific options
      # Output: Boolean
      Bgo::Specification.new( :export, 
                                    'fn(Filename, Project, Hash)',
                                     [String, Bgo::Process, Hash], 
                                     [[TrueClass, FalseClass]]
                                    ) 
    end
  end
end
