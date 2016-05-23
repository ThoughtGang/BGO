#!/usr/bin/env ruby
# :title: Bgo::Commands::CreateRevision
=begin rdoc
BGO command to create a new Revision in an Address Container.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

module Bgo
  module Commands

=begin rdoc
A command to create a Revision in an AddressContainer in a project or stream.
=end
    class CreateRevisionCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Create a BGO Revision in an AddressContainer'
      usage "#{Commands.data_model_usage} [-n] [-c str] OBJPATH"
      help "Create a Revision object for an AddressContainer in a Project or stream.
Category: plumbing

This creates a BGO Revision object in an AddressContainer object.

Options:
  -c, --comment string   Comment for Revision object
  -n, --not-current      Do not set current_revision to the new Revision
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

The OBJPATH argument identifies the AddressContainer object (e.g. a Map or
Section) in which the Revision will be created. If the OBJPATh identifies
a Target object, then every AddressContainer in the Target will have a
revision added. If the OBJPATH identifies a Block object, then the change
will be propagated to the Block#container object


Note: This will set AddressContainer#current_revision to the new Revision 
unless the -n option is provided.

Examples:
  # Create a new Revision in Map 0x8040100 of Process 999
  bgo revision-create /process/999/map/0x8040100
  # Create Revision in Map 0x100 without making it the current_changset
  bgo revision-create -n /process/999/map/0x100

See also: address, revision, revision-delete, revision-edit"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          obj = state.item_at_obj_path ident
          if ! obj
            $stderr.puts "Invalid object_path : #{ident}"
            next
          end

          obj = obj.container if obj.kind_of? Bgo::Block

          if not obj.respond_to? :add_revision
            $stderr.puts "Invalid AddressContainer or Target: #{ident}"
            next
          end

          ((obj.respond_to? :address_containers) ? obj.address_containers : \
                                                   [obj]).each do |ac|
            old_ident = ac.current_revision if options.keep_current_cs
            r = ac.add_revision
            r.comment = options.comment if options.comment
            ac.revision = old_ident if options.keep_current_cs
          end

        end

        state.save("Revisions added to #{options.idents.join ','} by cmd REVISION CREATE")

        true
      end

      def self.get_options(args)
        options = super
        options.idents = []

        options.comment = nil
        options.keep_current_cs = false

        opts = OptionParser.new do |opts|
          opts.on( '-c', '--comment string' ) { |str| options.comment = str }
          opts.on( '-n', '--not-current' ) { options.keep_current_cs = true  }

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

      def self.fetch_process(state, ident)
        state.project ? state.project.process(ident) :
                        (state.working_data[:processes] || {})[ident]
      end
    end

  end
end

