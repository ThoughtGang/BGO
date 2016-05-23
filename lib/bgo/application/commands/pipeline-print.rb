#!/usr/bin/env ruby
# :title: Bgo::Commands::PipelinePrint
=begin rdoc
BGO Command to print a JSON Pipeline to stdout.
=end

require 'bgo'
require 'bgo/application/command'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/util/json'

module Bgo
  module Commands
    class PipelinePrintCommand < Application::Command
      disable_plugins
      end_pipeline
      summary 'Print Command Pipeline to STDOUT in formatted JSON'
      usage ''
      help 'Print a formatted version of Command Pipeline JSON to STDOUT.
Category: plumbing

De-serialize a BGO Command Pipeline from JSON and pretty-print it to STDOUT.
Note: This actually instantiates the Pipeline from JSON before printing it,
      due to a limitation in JSON.pretty_generate. Therefore it may not be
      suitable for debugging command Pipelines that break serialization.

Options:
  None.

Examples:
  bgo project | bgo pipeline-print

See also: pipeline-history, pipeline-tree
      '

      def self.invoke_with_state(state, options)
        puts JSON.pretty_generate state
      end

    end
  end
end
