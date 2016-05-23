#!/usr/bin/env ruby
# :title: Bgo::Commands::PluginDirs
=begin rdoc
BGO command to list plugin directories

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/plugin_mgr'

module Bgo
  module Commands

=begin rdoc
A command to list plugin search path
=end
    class PluginDirsCommand < Application::Command
# ----------------------------------------------------------------------
      disable_pipeline
      summary 'List plugin directories'
      usage '[-f]'
      help 'This command lists the directories in the plugin search path. 
Category: porcelain

Options:
  -f, --full        Include non-existent directories

Examples:
  # List all detected plugin directories
  bgo plugin-dirs
  
  # List all possible plugin directories
  bgo plugin-dirs -f

See also: plugin-eval, plugin-help, plugin-info, plugin-list, plugin-specs
'
# ----------------------------------------------------------------------

      def self.invoke(args)
        options = get_options(args)
        Bgo::Application::PluginManager.plugin_dirs(options.show_all).each { |d|
          puts d
        }
      end

      def self.get_options(args)
        options = OpenStruct.new
        options.show_all = false

        opts = OptionParser.new do |opts|
          opts.on( '-f', '--full' ) { options.show_all = true }
        end

        opts.parse!(args)

        return options
      end

    end

  end
end

