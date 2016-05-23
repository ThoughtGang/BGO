#!/usr/bin/env ruby
# :title: Bgo::Commands::CreateBlock
=begin rdoc
BGO command to create a new Block

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/block'

module Bgo
  module Commands

=begin rdoc
A command to create a Block in a project or stream.
=end
    class CreateBlockCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Create a BGO Block inside a parent Block'
      usage "#{Commands.data_model_usage} [-c str] [-r num] OBJPATH VMA SIZE"
      help "Create a Block inside a Bgo Block in a Project or stream.
Category: plumbing

This creates a BGO Block object inside an existing Block. Note that all Target
objects have a default block spanning their contents.


Options:
  -c, --comment string      Comment for Block object
  -r, --revision integer    Revision number to apply block to
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

The OBJPATH argument identifies the parent block. The VMA argument is the start
address of the Block, and the SIZE argument is the size of the Block in bytes.

Examples:
  # Create a Block from 0x8040100 to 0x80401FF in Process 999
  bgo block-create process/999 0x8040100 0x100

See also: "
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        obj = state.item_at_obj_path options.ident
        if ! obj.kind_of? Bgo::Block
          if ! obj.respond_to? :block
            $stderr.puts "Invalid Block or Container: #{options.ident}"
            return false
          end
          obj = obj.block
        end

        obj.create_child(options.vma, options.size, options.revision)

        true
      end

      def self.get_options(args)
        options = super

        options.ident = nil
        options.vma = nil
        options.size = nil
        options.rev = nil
        options.comment = nil

        opts = OptionParser.new do |opts|
          opts.on( '-r', '--revision num' ) { |n| options.rev = Integer(n) }
          opts.on( '-c', '--comment string' ) { |str| options.comment = str }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 3
        options.ident = args.shift
        options.vma = Integer(args.shift)
        options.size = Integer(args.shift)

        return options
      end

    end

  end
end

