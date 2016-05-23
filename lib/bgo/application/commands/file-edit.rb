#!/usr/bin/env ruby
# :title: Bgo::Commands::FileEdit
=begin rdoc
BGO command to modify TargetFile objects

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/model_item'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/file'

module Bgo
  module Commands

=begin rdoc
A command to edit project files
=end
    class FileEditCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Edit BGO TargetFile details'
      usage "#{Commands.data_model_usage} [-c cmt] IDENT [...]"
      help "Modify TargetFile objects in a Project or from STDIN.
Category: plumbing

Options:
  -c, --comment string    Set file comment
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

IDENT can be either a File ident or the object path of a File object.

Examples:
  # Set the comment for the specified TargetFile
  bgo file-edit -c 'Output of latest build' /tmp/a.out
  # Set comment for child file 'a.out' in parent file 'bin.tgz'
  bgo file-edit -c 'inner file' file/bin.tgz/file/a.out

See also: file, file-create, file-delete
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          f = Commands.file_ident_or_path(state, ident)
          if f
            f.comment = options.comment if options.comment
          else
            $stderr.puts "File '#{ident}' not found in input"
          end
        end
        state.save("#{options.idents.join ','} modified by cmd FILE EDIT")

        true
      end

      def self.get_options(args)
        options = super

        options.idents = []
        options.comment = nil

        opts = OptionParser.new do |opts|

          opts.on( '-c', '--comment string' ) do |new_cmt|
            options.comment = new_cmt
          end

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

