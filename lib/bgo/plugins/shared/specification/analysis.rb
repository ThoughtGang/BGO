#!/usr/bin/env ruby                                                             
# :title: Bgo::Plugin::Specification::Analyze
=begin rdoc
Specification for 2G and 3G analysis plugins

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'tg/plugin'

require 'bgo/analysis_results'
require 'bgo/target'
require 'bgo/block'

module Bgo
  module Plugin
    module Spec

      # Analyze the target, returning an AnalysisResults object.
      # Input: Bgo::TargetObject|Block, Hash of analysis options
      # Output: AnalysisResults object
      TG::Plugin::Specification.new( :analysis, 
                                    'fn(Target|Block, Hash)',
                                     [[Bgo::TargetObject, Bgo::Block], Hash], 
                                     [AnalysisResults]
                                    )
    end
  end
end
