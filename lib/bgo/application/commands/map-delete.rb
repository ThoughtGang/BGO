#!/usr/bin/env ruby
# :title: Bgo::Commands::DeleteProcessMap
=begin rdoc
BGO command to delete Map objects

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

module Bgo
  module Commands

=begin rdoc
A command to delete process maps from a project or stream.
=end
    class DeleteProcessMapCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Delete BGO Map objects'
      usage "#{Commands.data_model_usage} OBJPATH [...]"
      help "Delete Map objects from a Project or stream.
Category: plumbing

Options:
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

OBJPATH identifies the Map object to be deleted.

Examples:
  # Delete Map for VMA 0x8040100 from Process 999
  bgo map-delete process/999/map/0x8040100

See also: map, map-create, map-edit
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        options.idents.each do |ident|
          m = state.item_at_obj_path ident
          raise "Not a Bgo::Map object: #{ident}" if ! m.kind_of? Bgo::Map
          m.parent_obj && m.parent_obj.remove_map(m.vma)
        end
        state.save("#{options.idents.join ','} removed by cmd MAP DELETE")

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

      def self.delete_map(p, vma)
        m = p.map(vma)
        raise ("Map %X not found in process %s" % [vma, p.ident.to_s]) if ! m
        p.remove_map(vma)
      end

    end

  end
end

