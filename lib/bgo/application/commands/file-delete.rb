#!/usr/bin/env ruby
# :title: Bgo::Commands::DeleteFile
=begin rdoc
BGO command to delete TargetFile objects

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/model_item'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

module Bgo
  module Commands

=begin rdoc
A command to delete files from a project or stream.
=end
    class DeleteFileCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Delete BGO TargetFile objects'
      usage "#{Commands.data_model_usage} IDENT [...]"
      help "Delete TargetFile objects from a Project or stream.
Category: plumbing

Options:
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

One or more IDENT arguments must be provided. IDENT can be either a File ident 
or the object path of a File object.

Examples:
  # Delete the specified TargetFile
  bgo file-delete /tmp/a.out
  # Delete the child file 'a.out' in the parent file '/tmp/bin.tgz'
  bgo file-delete file/^tmp^bin.tgz/file/a.out

See also: file, file-create, file-edit
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          f = Commands.file_ident_or_path(state, ident)
          if f
            state.remove_file(f.ident) 
          else
            $stderr.puts "File '#{ident}' not found in input"
          end
        end
        state.save("#{options.idents.join ','} removed by cmd FILE DELETE")

        true
      end

      def self.get_options(args)
        options = super

        options.idents = []

        opts = OptionParser.new do |opts|
          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        raise "Insufficient arguments" if args.count < 1
        opts.parse!(args)

        while args.length > 0
          options.idents << args.shift
        end

        return options
      end

    end

  end
end

