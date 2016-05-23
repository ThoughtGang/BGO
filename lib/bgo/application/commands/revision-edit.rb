#!/usr/bin/env ruby
# :title: Bgo::Commands::ProcessEdit
=begin rdoc
BGO command to modify Revision objects in an AddressContainer.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

module Bgo
  module Commands

=begin rdoc
A command to edit a Revision to an AddressContainer in a project or stream.
=end
    class EditRevisionCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Edit BGO Revision details'
      usage "#{Commands.data_model_usage} [-c str] OBJPATH [...]"
      help "Modify Revision objects in a Project or stream.
Category: plumbing

Options:
  -c, --comment string   Comment for Revision object
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

The OBJPATH identifies the Revision object to be modified.

Examples:
  # Set the comment of Revision 2 in Map 0x8040100 of Process 999
  bgo revision-edit -c 'patch tues' /process/999/map/0x8040100/revision/2

See also: address, revision, revision-create, revision-delete
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          obj = state.item_at_obj_path ident
          if ! obj.kind_of? Bgo::ImageRevision
            $stderr.puts "Invalid object path: #{ident}"
            next
          end

          obj.comment = options.comment if options.comment
        end

        state.save("#{options.idents.join ','} modified by cmd REVISION EDIT")

        true
      end

      def self.get_options(args)
        options = super
        options.idents = []

        options.comment = nil

        opts = OptionParser.new do |opts|
          opts.on( '-c', '--comment string' ) { |str| options.comment = str }

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

