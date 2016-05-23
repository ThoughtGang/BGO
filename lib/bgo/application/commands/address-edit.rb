#!/usr/bin/env ruby
# :title: Bgo::Commands::AddressEdit
=begin rdoc
BGO command to modify Address objects

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/address'

# TODO: name, contents, etc

module Bgo
  module Commands

=begin rdoc
A command to edit address objects
=end
    class AddressEditCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Edit BGO Address details'
      usage "#{Commands.data_model_usage} [-c cmt] OBJPATH [...]"
      help "Modify Address objects in a Project or from STDIN.
Category: plumbing

Options:
  -c, --comment string   Set Address comment
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

OBJPATH identifies the Address object to be modified.

Examples:
  # Set the comment for Address 0x1000 in Process 999
  bgo address-edit -c 'start of header struct' process/999/0x1000
  bgo address-edit -c 'start of header struct' process/999/address/0x1000
  bgo address-edit -c 'start of header struct' \
    process/999/address/0x1000/revision/0
  # Set the comment for Address 0x1000 in Map 0 of Process 999
  bgo address-edit -c 'start of header struct' process/999/map/0/0x1000
  # Set the comment for Address 0x500 in Revision 2 of File /tmp/a.out
  bgo address-edit -c 'Entry point' file/^tmp^a.out/0x500/revision/2

See also: address, address-delete, file-address-create, process-address-create
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          a = state.item_at_obj_path ident
          if not a.kind_of? Bgo::Address
            $stderr.puts "Not a Bgo::Address object: #{ident}"
            next
          end

          a.comment = options.comment if options.comment
        end
        state.save("#{options.idents.join ','} modified by cmd ADDRESS EDIT")

        true
      end

      def self.get_options(args)
        options = super

        options.idents = []
        options.comment = nil

        opts = OptionParser.new do |opts|

          opts.on( '-c', '--comment string' ) { |cmt| options.comment = cmt }

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
