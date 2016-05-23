#!/usr/bin/env ruby
# :title: Bgo::Commands::Image
=begin rdoc
BGO command to list and examine Image objects

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
A command to show project images
=end
    class ImageCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      end_pipeline
      summary 'List or view BGO Image objects'
      usage "#{Commands.data_model_usage} [-clirx] [--full] [IDENT]"
      help "List/View Image objects in a Project or from STDIN.
Category: porcelain

Options:
  -c, --comment        Show or set image comment
  -i, --ident          Show image ident [default]
  -l, --list           List all images
  -r, --raw            Output the raw binary contents of image
  -x, --hexdump        Output a hexdump of contents of image
  --full               Produce detailed output
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}
Note: The --stdout option has no effect in this command.
      
To list all Images in the Project, the command can be invoked with no
arguments.

To view an Image, the IDENT argument must be provided. The -x option can be
used to display a hexdump of the contents of the image.

Examples:
  # List all Image objects in the Project in ~/my_project.bgo
  bgo image -p ~/my_project.bgo
  # List the contents of the specified Image
  bgo image -x 007d83421161a5a0dcefbc41d0eb94fc40fe091e
  # Display only the comment of the specified Image
  # (note that the optional argument for -c conflicts with Image ident arg)
  bgo image -c --nop 007d83421161a5a0dcefbc41d0eb94fc40fe091e
  # Dump the binary contents of the specified image
  bgo image -r 0bd8a2794ea254b6c04eecd2fcbf1fa4fda439ae > image_data.bin

See also: image-create, image-delete, image-edit
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          img = state.image ident
          if img
            show_ident(img, options) if options.show_ident
            show_comment(img, options) if options.show_comment
            show_hex_contents(img, options) if options.show_hex
            show_raw_contents(img, options) if options.show_raw
          else
            $stderr.puts "Image '#{ident}' not found in input"
          end
        end

        if options.list_images
          puts "Images:" if options.details
          state.images.each { |img| list_image(img, options) }
        end
        true
      end

      def self.get_options(args)
        options = super

        options.idents = []

        options.show_ident = false
        options.show_comment = false
        options.show_hex = false
        options.show_raw = false
        options.details = false
        options.list_images = false

        opts = OptionParser.new do |opts|

          opts.on( '-i', '--ident' ) { options.show_ident = true }
          opts.on( '-r', '--raw' ) { options.show_raw = true }
          opts.on( '-x', '--hexdump' ) { options.show_hex = true }
          opts.on( '-c', '--comment' ) { options.show_comment = true }
          opts.on( '-l', '--list' ) { options.list_images = true }
          opts.on( '--full' ) { select_show_full options }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        while args.length > 0
          options.idents << args.shift
        end

        options.list_images = true if (options.idents.empty?)
        select_show_full(options) if not show_option_selected(options)

        return options
      end

      def self.show_option_selected(options)
        options.show_ident || options.show_comment || options.show_raw ||
        options.show_hex
      end

      def self.select_show_full(options)
        options.show_ident = options.show_comment = options.show_hex = true
        options.details = true
      end

      def self.fetch_image(state, ident)
        return state.project.image(ident) if state.project
        (state.working_data[:images] || {})[ident]
      end

      def self.show_ident(img, options)
        puts "#{options.details ? 'Ident: ' : ''}#{img.ident}"
      end

      def self.show_comment(img, options)
        txt = img.comment ? img.comment.text : ''
        puts "#{options.details ? 'Comment: ' : ''}#{txt}"
      end

      def self.show_raw_contents(img, options)
        $stdout.write img.contents
      end

      def self.show_hex_contents(img, options)
        puts "Contents:" if options.details
        idx = 0
        img.contents.bytes.each do |byte| 
          print "%08X:" % [idx] if (idx % 16 == 0)
          print " %02X" % byte
          idx += 1
          print "\n" if idx % 16 == 0
        end
        print "\n" if idx % 16 != 0
      end

      def self.list_image(obj, options)
        if obj.kind_of? Bgo::Image
          puts(options.details ? obj.inspect : obj.ident)
        else
          puts "Not a BGO Image: #{obj.class}"
        end
      end

    end

  end
end

