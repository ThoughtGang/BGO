#!/usr/bin/env ruby
# :title: Bgo::Commands::CreateRemoteImage
=begin rdoc
BGO command to create a new RemoteImage object.

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
A command to create an RemoteImage in a project or stream.
=end
    class CreateRemoteImageCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Create a BGO RemoteImage'
      usage "#{Commands.data_model_usage} [-c str] [-s num] [-i str] STRING"
      help "Create an RemoteImage object in a Project or stream.
Category: plumbing

This creates a BGO RemoteImage object. STRING is the name of a file which 
contains the Image contents. If the file does not currently exist, the -s and 
-i arguments must be used to specify a size and ident for the image.

Options:
  -c, --comment string    Comment for RemoteImage object
  -i, --ident string      Ident for RemoteImage (e.g. SHA256 of contents)
  -s, --size num          Size of RemoteImage contents
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

Examples:
  bgo image-create-remote memdump.bin

See also: image, image-create, image-create-virtual, image-delete, image-edit"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        img = state.add_remote_image(options.path, options.size, options.ident)
        img.comment = options.comment if img && options.comment
        state.save("RemoteImage added by cmd IMAGE-CREATE-REMOTE" )
        true
      end

      def self.get_options(args)
        options = super

        options.path = nil
        options.ident = nil
        options.size = nil
        options.comment = nil   # image comment attribute

        opts = OptionParser.new do |opts|
          opts.on( '-c', '--comment string' ) { |str| options.comment = cmt }
          opts.on( '-i', '--ident string' ) { |str| options.ident = str }
          opts.on( '-s', '--size num' ) { |x| options.size = Integer(x) }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1
        options.path = args.shift

        return options
      end

    end

  end
end

