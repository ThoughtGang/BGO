#!/usr/bin/env ruby
# :title: Bgo::Commands::PipelineHistory
=begin rdoc
BGO Command to print a Pipeline command history to stdout.
=end

require 'bgo'
require 'bgo/application/command'
require 'bgo/application/commands/shared/pipeline'

module Bgo
  module Commands
    class PipelineHistoryCommand < Application::Command
      disable_plugins
      end_pipeline
      summary 'Print Command Pipeline History to STDOUT'
      usage ''
      help 'Print command history of Pipeline to STDOUT.
Category: plumbing

De-serialize a BGO Command Pipeline from JSON and print its command history.

Options:
  None.

Examples:
  bgo project | bgo pipeline-history

See also: pipeline-print, pipeline-tree
      '

      def self.invoke_with_state(state, options)
        puts state.command_history.join("\n")
      end

    end
  end
end
