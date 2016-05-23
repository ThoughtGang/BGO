#!/usr/bin/env ruby
# :title: Bgo::Commands::DeleteImage
=begin rdoc
BGO command to delete Image objects

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

module Bgo
  module Commands

=begin rdoc
A command to delete images from a project or stream.
=end
    class DeleteImageCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Delete BGO Image objects'
      usage "#{Commands.data_model_usage} IDENT [...]"
      help "Delete Image objects from a Project or stream.
Category: plumbing

Options:
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

      
One or more IDENT arguments must be provided.

Examples:
  # Delete the specified Image
  bgo image-delete 007d83421161a5a0dcefbc41d0eb94fc40fe091e
  # Delete first Image whose ident begins with '007d'
  bgo image-delete 007d
  # Delete first VirtualImage
  bgo image-delete virtual

See also: image, image-create
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        options.idents.each do |ident|
          state.remove_image(ident)
        end
        state.save("Idents deleted by cmd IMAGE DELETE")   

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

