#!/usr/bin/env ruby
# :title: Bgo::Commands::Tag
=begin rdoc
BGO command to add, remove, or list Tags for ModelItem objects

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

module Bgo
  module Commands

=begin rdoc
A command to manipulate BGO data model object Tags
=end
    class TagCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Manage the tags of a BGO data model item'
      usage "#{Commands.data_model_usage} [-r] OBJPATH [TAG] [...]"
      help "Add, remove, and list the Tags of a BGO object.
Category: porcelain

Options:
  -r, --remove           Remove the specified tags.
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

Examples:
  # Display tags for Process 1001
  bgo tag process/1001 
  # Add tag 'needs_cflow_analysis' to Process 1001
  bgo tag process/1001 needs_cflow_analysis
  # Remove tag 'needs_cflow_analysis' from Process 1001
  bgo tag -r process/1001 needs_cflow_analysis

See also: comment, inspect, properties"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        return false if (! options.path)

        obj = state.item_at_obj_path options.path
        if (! obj)
          $stderr.puts "Invalid object path '#{options.path}'"
          return false
        end
        
        if options.tags.empty?
          $stdout.puts obj.details_clean(obj.details_tags).join("\n")
          end_pipeline
        else
          options.tags.each do |t|
            options.remove ? obj.tags.delete(t) : obj.tags.add(t)
          end
          state.project.update
        end

        true
      end

      def self.get_options(args)
        options = OpenStruct.new
        options.path = nil
        options.tags = []
        options.remove = false

        opts = OptionParser.new do |opts|
          opts.on( '-r', '--remove' ) {options.remove = true}

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        options.path = args.shift
        while args.length > 0
          options.tags << args.shift.to_sym
        end

        return options
      end

    end

  end
end

