#!/usr/bin/env ruby
# :title: Bgo::Commands::PipelineTree
=begin rdoc
BGO Command to print Pipeline working_data object tree to stdout.
=end

require 'bgo'
require 'bgo/application/command'
require 'bgo/application/commands/shared/pipeline'

module Bgo
  module Commands
    class PipelineTreeCommand < Application::Command
      disable_plugins
      end_pipeline
      summary 'Print Command Pipeline object tree'
      usage ''
      help 'Print Command Pipeline working_data object tree to STDOUT.
Category: plumbing

De-serialize a BGO Command Pipeline from JSON and print its object tree to 
STDOUT. The tree consists of paths representing each BGO ModelItem object
instance.

Options:
  None.

Examples:
  bgo project | bgo pipeline-tree

See also: pipeline-history, pipeline-print
'

      def self.invoke_with_state(state, options)
        state.working_data.sort { |a,b| a[0].to_s <=> b[0].to_s }.each do |k,h|
          h.sort { |a,b| a[0] <=> b[0] }.each { |ident, obj| print_object obj }
        end
      end

      def self.print_object(obj)
        $stdout.puts obj.obj_path
        obj.class.child_iterators.each do |sym|
          obj.send(sym).each { |child| print_object child }
        end
      end

    end
  end
end
