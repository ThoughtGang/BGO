#!/usr/bin/env ruby
# :title: Bgo::Commands::CreateImage
=begin rdoc
BGO command to create a new Image object.

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
A command to create an Image in a project or stream.
=end
    class CreateImageCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Create a BGO Image'
      usage "#{Commands.data_model_usage} [-c str] [-xo] STRING"
      help "Create an Image object in a Project or stream.
Category: plumbing

This creates a BGO Image object whose contents are STRING. By default, STRING
is the name of a file to read as the Image contents. The -x and -o arguments
can be used to treat STRING as a hex or octal representation of the Image
contents (instead of as a filename).

Options:
  -c, --comment string    Comment for Image object
  -o, --octal             Data string is in ASCII octal bytes ('0377 0001'...)
  -x, --hex               Data string is in ASCII hex bytes ('FF 01'...)
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

Examples:
  # Add a binary image for the file 'memdump.bin'
  bgo image-create memdump.bin
  # Add a binary image consisting of 8 0xCC (int3 in x86) bytes:
  bgo image-create -x 'CC CC CC CC CC CC CC CC'

See also: file-create, image, image-create-remote, image-create-virtual, 
          image-delete, image-edit"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        options.images.each { |path| create_image(options, state, path) }
        state.save("Image added by cmd IMAGE-CREATE" )
        true
      end

      def self.create_image(options, state, str)
        buf = ''
        if options.hex
          buf = str.split(' ').collect { |c| c.hex }.pack('C*')
        elsif options.octal
          buf = str.split(' ').collect { |c| c.oct }.pack('C*')
        else
          buf = File.binread(str)
        end

        img = state.add_image buf
        img.comment = options.comment if img && options.comment
      end

      def self.get_options(args)
        options = super

        options.hex = options.octal = false
        options.comment = nil   # image comment attribute
        options.images = []

        opts = OptionParser.new do |opts|
          opts.on( '-c', '--comment string' ) { |str| options.comment = cmt }
          opts.on( '-x', '--hex' ) { options.hex = true }
          opts.on( '-o', '--octal' ) { options.octal = true }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1
        while args.length > 0
          options.images << args.shift
        end

        return options
      end

    end

  end
end

