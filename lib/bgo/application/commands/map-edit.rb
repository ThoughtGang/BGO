#!/usr/bin/env ruby
# :title: Bgo::Commands::ProcessMapEdit
=begin rdoc
BGO command to modify Map objects

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/map'

module Bgo
  module Commands

=begin rdoc
A command to edit process maps
=end
    class ProcessMapEditCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Edit BGO Map details'
      usage "#{Commands.data_model_usage} [-cf str] [-Cosv num] OBJPATH [...]"
      help "Modify Process Map objects in a Project or from STDIN.
Category: plumbing

Options:
  -c, --comment string   Set Map comment
  -C, --changeset num    Set Map current Changeset
  -f, --flags string     Set Map flags (e.g. 'rwx' or 'r-x')
  -o, --offset num       Set offset of Map in Image
  -s, --size num         Set size of Map in bytes
  -v, --vma num          Set Map load address (VMA)
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

OBJPATH identifies the Map object to be modified.

Examples:
  # Set the comment for the specified Process Map
  bgo map-edit -c 'read-only data from image' process/999/map/0x4000
  # Re-map Image from 0x04000 to 0x08000 in Process 999
  bgo map-edit -v 0x08000 process/999/map/0x04000
  # Change flags of Map 0x4200 to 'rwx'
  bgo map-edit -f 'rwx' process/999/map/0x4200

See also: map, map-create, map-delete
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

          options.idents.each do |ident|
            m = state.item_at_obj_path ident
            raise "Invalid object path: #{ident}" if ! m
            raise "Not a Bgo::Map object: #{ident}" if ! m.kind_of? Bgo::Map

            m.comment = options.comment if options.comment
            m.changeset = options.changeset if options.changeset
            m.flags = options.flags if options.flags 
            m.offset = options.offset if options.offset
            m.size = options.size if options.size
            m.parent_obj.rebase_map(m.vma, options.vma) if options.vma
          end
          state.save("#{options.idents.join ', '} modified by cmd MAP EDIT")

        true
      end

      def self.get_options(args)
        options = super

        options.idents = []

        options.comment = nil
        options.changeset = nil
        options.flags = nil
        options.offset = nil
        options.size = nil
        options.vma = nil

        opts = OptionParser.new do |opts|

          opts.on( '-c', '--comment string' ) { |cmt| options.comment = cmt }
          opts.on( '-C', '--changeset num' ){|n| options.changeset = Integer(n)}
          opts.on( '-f', '--flags string' ) do |str|
            arr = str.split('')
            options.flags = Bgo::Map.validate_flags(arr) ? arr : nil
          end
          opts.on( '-o', '--offset num' ) { |n| options.offset = Integer(n) }
          opts.on( '-s', '--size num' ) { |n| options.size = Integer(n) }
          opts.on( '-v', '--vma num' ) { |n| options.vma = Integer(n) }

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

