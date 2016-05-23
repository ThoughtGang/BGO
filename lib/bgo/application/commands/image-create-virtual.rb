#!/usr/bin/env ruby
# :title: Bgo::Commands::CreateVirtualImage
=begin rdoc
BGO command to create a new VirtualImage

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/image'

module Bgo
  module Commands

=begin rdoc
A command to create an VirtualImage in a project or stream.
=end
    class CreateVirtualImageCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Create a BGO VirtualImage'
      usage "[-s int] [-c str] [STRING]"
      help "Create a VirtualImage object in a Project or stream.
Category: plumbing

This creates a BGO VirtualImage object using the fill STRING. The default size 
of an image is 1024 bytes; the default fill string is 0x00.

Options:
  -c, --comment string   Comment for VirtualImage object
  -o, --octal            Fill string is in ASCII octal bytes ('0377 0001'...)
  -s, --size num         Size of the image in bytes [default 1024]
  -x, --hex              Fill string is in ASCII hex bytes ('FF 01'...)
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

Examples:
  # Create an image of 1024 bytes filled with the NULL (0x00) byte
  bgo image-create-virtual
  # Create an image of 1024 bytes filled with the 0xCC byte
  bgo image-create-virtual -x 'CC'
  # Create an image of 100 bytes filled with the 0x90 byte
  bgo image-create-virtual -x -s 100 '90'
  # Create an image of 4096 bytes filled with the 0377 byte
  bgo image-create-virtual -o -s 4096 '0377'
  # Create an image of 600 bytes filled with the repeated string 'abcdef'
  bgo image-create-virtual -s 600 'abcdef'

See also: image, image-create, image-delete, image-edit"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        fill = get_fill(options)
        img = state.add_virtual_image fill, options.size
        img.comment = options.comment if img && options.comment
        state.save("Image added by cmd IMAGE-CREATE-VIRTUAL" )

        true
      end

      def self.get_fill(options)
        if options.hex
          options.fill.split(' ').collect { |c| c.hex }.pack('C*')
        elsif options.octal
          options.fill.split(' ').collect { |c| c.oct }.pack('C*')
        else
          options.fill
        end
      end

      def self.get_options(args)
        options = super

        options.hex = options.octal = false
        options.fill = "\000"
        options.size = 1024
        options.comment = nil   # image comment attribute

        opts = OptionParser.new do |opts|
          opts.on( '-c', '--comment string' ) { |str| options.comment = str }
          opts.on( '-s', '--size num' ) { |num| options.size = num.to_i }
          opts.on( '-o', '--octal' ) { options.octal = true }
          opts.on( '-x', '--hex' ) { options.hex = true }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        options.fill = args.shift if args.length > 0

        return options
      end

    end

  end
end

