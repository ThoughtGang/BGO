#!/usr/bin/env ruby
# :title: Bgo::Commands::DeleteAddress
=begin rdoc
BGO command to delete an Address object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/address'

module Bgo
  module Commands

=begin rdoc
A command to delete file addresses from a project or stream.
=end
    class DeleteAddressCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Delete BGO Address objects'
      usage "#{Commands.data_model_usage} OBJPATH [...]"
      help "Delete Address objects from a Project or stream.
Category: plumbing

#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

OBJPATH identifies the Address object to be deleted.

Examples:
  # Delete the addresses 0x1000 and 0x1004 from TargetFile '/tmp/a.out'
  bgo address-delete file/^tmp^a.out/0x1000 file/^tmp^a.out/0x1004
  # Delete Address 0x500 from Revision 2 in /tmp/a.out
  bgo address-delete file/^tmp^a.out/0x500/revision/2
  # Delete Address 0x8040199 from Revision 1 in Process 999
  bgo address-delete process/999/0x8040199/revision/1

See also: address, address-create, address-edit
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          a = state.item_at_obj_path ident
          raise "Not an Address object: #{ident}" if ! a.kind_of? Bgo::Address
          a.parent_obj && a.parent_obj.remove_address(a.vma)

        end
        state.save("#{options.idents.join ','} removed by cmd ADDRESS DELETE")

        true
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
