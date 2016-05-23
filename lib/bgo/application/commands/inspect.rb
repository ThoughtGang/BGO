#!/usr/bin/env ruby
# :title: Bgo::Commands::Inspect
=begin rdoc
BGO command to inspect ModelItem objects

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

module Bgo
  module Commands

=begin rdoc
A command to display BGO data model objects
=end
    class InspectCommand < Application::Command
# ----------------------------------------------------------------------
      end_pipeline
      disable_plugins
      summary 'Display details of a BGO data model item'
      usage "#{Commands.data_model_usage} [-jr] OBJPATH [...]"
      help "Print the detailed contents of a BGO object by its path.
Category: porcelain

Options:
  -j, --json             Serialize object to JSON.
  -r, --recurse          Include object children in JSON serialization.
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

Examples:
  # Display human-readable details of address 0x8040100 in Process 1001
  bgo inspect process/1001/address/0x80401000
  # Display human-readable details of Process 1001 and File a.out
  bgo inspect process/1001 file/a.out
  # Serialize address 0x8040100 in Process 1001 to JSON
  bgo inspect -j process/1001/address/0x80401000
  # Serialize Process 1001 and File a.out to JSON, including all children
  bgo inspect -jr process/1001 file/a.out

See also: info, pipeline-print"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        return true if options.paths.empty?

        if options.json
          puts generate_json(state, options)
        else
          prev = false
          options.paths.each do |ident|
            obj = state.item_at_obj_path(ident)
            puts "\n" if prev
            puts obj ? obj.details.join("\n") : not_found(ident)
            prev = true
          end
        end

        true
      end

      def self.not_found(ident)
        "Invalid object path: #{ident.inspect}"
      end

      def self.generate_json(state, options)
        objects = options.paths.map { |ident| 
          obj = state.item_at_obj_path(ident)
          if ! obj
            $stderr.puts not_found(ident)
            next
          end
          (obj.respond_to? :to_core_hash) && (! options.recurse) ? \
                                          obj.to_core_hash : obj.to_hash
        }.compact
        return if objects.empty?
    
        # Do not generate an array if there is only one object
        JSON.pretty_generate( (objects.length > 1 ? objects.first : objects), 
                              :max_nesting => 100)
      end

      def self.get_options(args)
        options = OpenStruct.new
        options.paths = []
        options.json = false
        options.recurse = false

        opts = OptionParser.new do |opts|
          opts.on( '-j', '--json' ) { options.json = true }
          opts.on( '-r', '--recurse' ) {options.recurse = true}

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        while args.length > 0
          options.paths << args.shift
        end

        return options
      end

    end

  end
end

