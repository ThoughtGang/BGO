#!/usr/bin/env ruby
# :title: Bgo::Commands::Process
=begin rdoc
BGO command to list and examine Process objects

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
A command to show project processes
=end
    class ProcessCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      end_pipeline
      summary 'List or view BGO Process objects'
      usage "#{Commands.data_model_usage} [-acCfil] [--full] [IDENT]"
      help "List/View Process objects in a Project or from STDIN.
Category: porcelain

Options:
  -a, --arch-info      Show architecture information for Process
  -c, --comment        Show Process comment
  -C, --command        Show Process command line
  -f, --file           Show filename for Process executable
  -i, --ident          Show Process ident
  -l, --list           List all processes
  --full               Produce detailed output
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}
Note: The --stdout option has no effect in this command.
      
To list all Processes in the Project, the command can be invoked with no
arguments.

To view a Process, the IDENT argument must be provided.  IDENT can be either
a Process ident or the object path of a Process object.

Examples:
  # List all Process objects in the Project in ~/my_project.bgo
  bgo process -p ~/my_project.bgo
  # Display only the comment of Process 1000
  bgo process -c 1000
  # Display the complete record for process 999 via its object path
  bgo process --full process/999

See also: process-create, process-delete, process-edit
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        if options.idents.empty?
          puts "Processes:" if options.details
          state.processes.each { |p| list_process(p, options) }
          return true
        end

        options.idents.each do |ident|

          p = Commands.process_ident_or_path(state, ident)
          if p
            if options.list_processes
              list_process(p, options)
              next
            end

            show_ident(p, options) if options.show_ident
            show_cmdline(p, options) if options.show_cmdline
            show_filename(p, options) if options.show_file
            show_arch_info(p, options) if options.show_arch_info
            show_comment(p, options) if options.show_comment
          else
            $stderr.puts "File '#{ident}' not found in input"
          end
        end

        true
      end

      def self.get_options(args)
        options = super

        options.idents = []

        options.show_ident = false
        options.show_file = false
        options.show_cmdline = false
        options.show_comment = false
        options.details = false
        options.list_processes = false

        opts = OptionParser.new do |opts|

          opts.on( '-a', '--arch-info' ) { options.show_arch_info = true }
          opts.on( '-f', '--file' ) { options.show_file = true }
          opts.on( '-c', '--comment' ) { options.show_comment = true }
          opts.on( '-C', '--command' ) { options.show_cmdline = true }
          opts.on( '-i', '--ident' ) { options.show_ident = true }
          opts.on( '-l', '--list' ) { options.list_files = true }
          opts.on( '--full' ) { select_show_full options }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        while args.length > 0
          options.idents << args.shift
        end

        select_show_full(options) if not show_option_selected(options)

        return options
      end

      def self.show_option_selected(options)
        options.show_ident || options.show_comment || options.show_cmdline ||
        options.show_file || options.show_arch_info
      end

      def self.select_show_full(options)
        options.show_ident = options.show_file = options.show_cmdline = true
        options.show_arch_info = options.show_comment = true
      end

      def self.show_ident(p, options)
        puts "#{options.details ? 'Object Path: ' : ''}#{p.obj_path}"
      end

      def self.show_cmdline(p, options)
        puts "#{options.details ? 'Command: ' : ''}#{p.command}"
      end

      def self.show_filename(p, options)
        puts "#{options.details ? 'Filename: ' : ''}#{p.filename}"
      end

      def self.show_arch_info(p, options)
        puts "#{options.details ? 'Arch Info: ' : ''}#{p.arch_info}"
      end

      def self.show_comment(p, options)
        txt = p.comment ? p.comment.text : ''
        puts "#{options.details ? 'Comment: ' : ''}#{txt}"
      end

      def self.list_process(obj, options)
        if obj.kind_of? Bgo::Process
          puts (options.details ? obj.inspect : obj.ident)
        else
          puts "Not a BGO Process: #{obj.class} #{obj.inspect}"
        end
      end

    end

  end
end

