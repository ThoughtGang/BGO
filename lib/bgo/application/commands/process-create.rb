#!/usr/bin/env ruby
# :title: Bgo::Commands::CreateProcess
=begin rdoc
BGO command to create a new Process object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/process'

# TODO: should file be required to exist?
module Bgo
  module Commands

=begin rdoc
A command to create a Process in a project or stream.
=end
    class CreateProcessCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Create a BGO Process'
      usage "#{Commands.data_model_usage} [-i id] [-fc str] CMDLINE"
      help "Create an Process object in a Project or stream.
Category: plumbing

This creates a BGO Process object. The ident for the process is specified with
the -i argument; if not supplied, the next unused process ID (beginning with 
1000) will be assigned.

The filename (-f) and CMDLINE provide descriptive information for the process.
The filename is optional and specifies the name or ident of a TargetFile 
object that is the main executable for the process. The CMDLINE option is
the command line entered by the user to start the process (e.g. 'ls -laF').
Note that all remaining arguments are cooncatenated to form CMDLINE.

Options:
  -i, --ident            Process identifier or PID
  -c, --comment string   Comment for Process object
  -f, --file ident       Ident or name of TargetFile for main executable
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

Examples:

  # Create a Process with PID 999 for the command 'nc -lU /var/tmp/dsocket'
  bgo process-create -i 999 'nc -lU /var/tmp/dsocket'

See also: process, process-delete, process-edit"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        raise "No command line provided!" if ! options.cmdline || 
                                             (options.cmdline.empty?)
        
        options.ident ||= state.next_process_ident
        p = state.add_process( options.cmdline, options.file_ident, nil, 
                              options.ident )
        p.comment = options.comment if options.comment

        state.save("Process added by cmd PROCESS-CREATE")

        true
      end

      def self.get_options(args)
        options = super
        options.cmdline = nil
        options.comment = nil
        options.ident = nil
        options.file_ident = nil

        opts = OptionParser.new do |opts|
          opts.on( '-c', '--comment string' ) { |str| options.comment = str }
          opts.on( '-i', '--ident num' ) { |id| options.ident = Integer(id) }
          opts.on( '-f', '--file ident' ) { |id| options.file_ident = id }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1
        options.cmdline = args.join(' ')

        return options
      end

    end

  end
end

