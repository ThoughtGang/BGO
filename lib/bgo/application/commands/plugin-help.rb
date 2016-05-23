#!/usr/bin/env ruby
# :title: Bgo::Commands::PluginHelp
=begin rdoc
BGO command to list plugin help string

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/plugin_mgr'

module Bgo
  module Commands

=begin rdoc
A command to list plugin help string
=end
    class PluginHelpCommand < Application::Command
# ----------------------------------------------------------------------
      disable_pipeline
      summary 'Print Plugin help string'
      usage 'PLUGIN'
      help 'This command prints the help string of a specific plugin to STDOUT.
Category: porcelain

Examples:
  # Show help string for X86-Opcodes plugin
  bgo plugin-info X86-Opcodes

See also: plugin-dirs, plugin-eval, plugin-info, plugin-list, plugin-specs
'
# ----------------------------------------------------------------------

      def self.invoke(args)
        if args.count == 0
          puts "Plugin name is required"
          return false
        end

        plugin_name = args[0]

        Bgo::Application::PluginManager.  plugins.values.sort { |a,b|
            a.name <=> b.name }.each do |p|
          next if p.name != plugin_name

          puts p.help
        end
      end

    end

  end
end

