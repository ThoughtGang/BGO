#!/usr/bin/env ruby
# :title: Bgo::Commands::ImageEdit
=begin rdoc
BGO command to modify Image objects

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/image'

module Bgo
  module Commands

=begin rdoc
A command to edit project images
=end
    class ImageEditCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Edit BGO Image details'
      usage "#{Commands.data_model_usage} [-c cmt] IDENT"
      help "Modify Image objects in a Project or from STDIN.
Category: plumbing

Options:
  -c, --comment string  Set image comment
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

Examples:
  # Set the comment for the specified Image
  bgo image-edit -c 'Contents of network packet' \
                    007d83421161a5a0dcefbc41d0eb94fc40fe091e

See also: image, image-create
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        rv = true
        options.idents.each do |ident|
          img = state.image ident
          if ! img
            $stderr.puts "Image '#{ident}' not found in input"
            rv = false
            next
          end

          img.comment = options.comment if options.comment
          state.save("Ident '#{ident}' modified by cmd IMAGE-EDIT")
        end

        rv
      end

      def self.get_options(args)
        options = super

        options.idents = []
        options.comment = nil

        opts = OptionParser.new do |opts|

          opts.on( '-c', '--comment string' ) do |new_cmt| 
            options.comment = new_cmt
          end

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

