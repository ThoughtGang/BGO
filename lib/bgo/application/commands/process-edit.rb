#!/usr/bin/env ruby
# :title: Bgo::Commands::ProcessEdit
=begin rdoc
BGO command to modify Process objects

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/model_item'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/process'

module Bgo
  module Commands

=begin rdoc
A command to edit project Process objects
=end
    class ProcessEditCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Edit BGO Process details'
      usage "#{Commands.data_model_usage} [-cCf str] IDENT [...]"
      help "Modify Process objects in a Project or from STDIN.
Category: plumbing

Options:
  -c, --comment string  Set process comment
  -C, --command string  Set process command line
  -f, --file string     Set filename for process
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

IDENT can be either a Process ident or the object path of a Process object.

Examples:
  # Set the comment for Process 1000
  bgo process-edit -c 'Run target with no options' 1000 
  # Set the command and filename an invocation of /bin/ls for Process 999
  bgo process-edit -C 'ls -l' -f '/bin/ls' process/999

See also: process, process-create, process-delete
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          p = Commands.process_ident_or_path(state, ident)
          if p
            p.comment = options.comment if options.comment
            p.command = options.command if options.command
            p.filename = options.filename if options.filename
          else
            $stderr.puts "Process '#{options.ident}' not found in input"
          end
        end
        state.save("'#{options.idents.join ','}' modified by cmd PROCESS EDIT")

        true
      end

      def self.get_options(args)
        options = super

        options.idents = []
        options.comment = nil
        options.command = nil
        options.filename = nil

        opts = OptionParser.new do |opts|

          opts.on( '-c', '--comment string' ) { |cmt| options.comment = cmt }
          opts.on( '-C', '--command string' ) { |str| options.command = str }
          opts.on( '-f', '--file string' ) { |str| options.filename = str }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1
        while args.count > 0
          options.idents << args.shift
        end

        return options
      end

    end

  end
end

