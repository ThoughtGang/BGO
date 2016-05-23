#!/usr/bin/env ruby
# :title: Bgo::Commands::DeleteFileSection
=begin rdoc
BGO command to delete Section objects

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/model_item'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

module Bgo
  module Commands

=begin rdoc
A command to delete file sections from a project or stream.
=end
    class DeleteFileSectionCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Delete BGO Section objects'
      usage "#{Commands.data_model_usage} FILE IDENT [...]"
      help "Delete Section objects from a Project or stream.
Category: plumbing

Options:
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

One or more IDENT arguments must be provided.

Examples:
  # Delete the .text and .rodata sections from TargetFile '/tmp/a.out'
  bgo section-delete file/^tmp^a.out/section/.text \
                     file/^tmp^a.out/section/.rodata

See also: section, section-create, section-edit
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        options.idents.each do |ident| 
          s = state.item_at_obj_path ident
          raise "Invalid object path: #{ident}" if ! s
          raise "Not a Section object: #{ident}" if ! s.kind_of? Bgo::Section

          s.parent_obj && s.parent_obj.remove_section(s.ident)
        end
        state.save("#{options.idents.join ', '} removed by cmd SECTION DELETE")

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

