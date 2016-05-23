#!/usr/bin/env ruby
# :title: Bgo::Commands::DeleteProcess
=begin rdoc
BGO command to delete Process objects

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

module Bgo
  module Commands

=begin rdoc
A command to delete Process objects from a project or stream.
=end
    class DeleteProcessCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Delete BGO Process objects'
      usage "#{Commands.data_model_usage} IDENT [...]"
      help "Delete Process objects from a Project or stream.
Category: plumbing

Options:
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

One or more IDENT arguments must be provided. An IDENT can be either a Process
ident or the object path of a Process object.

Examples:
  # Delete Process 999
  bgo process-delete 999
  # Delete Process 1000 via its object path
  bgo process-delete procss/1000

See also: process, process-create
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          pid = get_pid(ident)
          raise "Invalid Process ident #{ident}" if ! pid
          state.remove_process(pid)
        end
        state.save("#{options.idents.join ','} removed by cmd PROCESS DELETE")

        true
      end

      def self.get_pid(ident)
        pid = Integer(ident) rescue nil
        pid || Integer(ident.split(File::SEPARATOR).last || '') rescue nil
      end

      def self.get_options(args)
        options = super

        options.idents = []

        opts = OptionParser.new do |opts|
          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1
        while args.length > 0
          options.idents << args.shift
        end

        return options
      end

    end
  end
end

