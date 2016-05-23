#!/usr/bin/env ruby
# :title: Bgo::Commands::LoadTarget
=begin rdoc
BGO command to run a load_target Plugin spec on a Process and one or more Files.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/model_item'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/plugin'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/application/plugin_mgr'

module Bgo
  module Commands

=begin rdoc
A command to run a load-target Plugin spec on a Process and one or more Files.
=end
    class LoadTargetCommand < Application::Command
# ----------------------------------------------------------------------
      summary 'Run a load_target plugin on TargetFile objects'
      usage "#{Commands.data_model_usage} #{Commands.plugin_usage} FILE [...]"
      help "Use a load_target Plugin to load files into a Project.
Category: porcelain

Options:

#{Commands.plugin_options_help}
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

Examples:

  # Run fittest :load_target plugin on /tmp/a.out 
  bgo load-target ^tmp^a.out
  # List all Disassembler plugins
  bgo plugin-specs -p load_target

See also: load, disasm, target-disasm"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        # get plugin
        options.plugin_opts = {} if (! options.plugin_opts.kind_of? Hash)
        args = [p, files, options.plugin_opts]
        plugin = Commands.plugin_for_spec(:load_target, options.plugin, *args)

        # perform analysis
        plugin.spec_invoke(:load_target, state, options.file_idents, *args)

        state.save("LOAD-TARGET command using plugin #{plugin.canon_name}")

        true
      end

      def self.get_options(args)
        options = super

        options.proc_ident = nil
        options.file_idents = []

        options.vma = 0

        opts = OptionParser.new do |opts|
          Commands.plugin_options(options, opts)
          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1

        options.file_idents = args

        return options
      end

    end

  end
end
