#!/usr/bin/env ruby
# :title: Bgo::Commands::DeleteRevision
=begin rdoc
BGO command to delete a Revision object from an AddressContainer object.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

module Bgo
  module Commands

=begin rdoc
A command to delete Revisions from an AddressContainer in a project or stream.
=end
    class DeleteRevisionCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Delete BGO Revision objects'
      usage "#{Commands.data_model_usage} OBJPATH [...]"
      help "Delete Revision objects from a Project or stream
Category: plumbing

This deletes a BGO Revision object from an AddressContainer object.

Options:
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

The OBJPATH argument identifies the Revision object in an AddressContainer.

Examples:
  # Delete Revision 2 from Map 0x8040100 in Process 999
  bgo revision-delete process/999/map/0x8040100/revision/2


See also: address, revision, revision-create, revision-edit"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          obj = state.item_at_obj_path ident
          if ! obj.kind_of? Bgo::ImageRevision
            $stderr.puts "Invalid object path: #{ident}"
            next
          end
          ac = obj.parent_obj
          if ac.respond_to? :remove_revision
            ac.remove_revision obj.ident
          else
            $stderr.puts "Invalid AddressContainer: #{ac.inspect}"
          end
        end

        state.save("#{options.idents.join ','} removed by cmd REVISION DELETE")

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

