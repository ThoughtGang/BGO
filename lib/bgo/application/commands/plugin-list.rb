#!/usr/bin/env ruby
# :title: Bgo::Commands::PluginList
=begin rdoc
BGO command to list plugins

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/plugin_mgr'

module Bgo
  module Commands

=begin rdoc
A command to list plugins
=end
    class PluginListCommand < Application::Command
# ----------------------------------------------------------------------
      disable_pipeline
      summary 'List plugins'
      usage '[pattern]'
      help 'This command lists plugins. 
Category: porcelain

List available plugins. The list can be narrowed using globs.

Options:
  pattern           A Plugin name to match, using * and ? for globbing.

Examples:
  # List all plugins
  bgo plugin-list

  # List all plugins matching the pattern "*agic*"
  bgo plugin-list \'*agic*\'

  # List all plugins matching the pattern "?fd"
  bgo plugin-list \'?fd\'

See also: plugin-dirs, plugin-eval, plugin-help, plugin-info, plugin-specs
'
# ----------------------------------------------------------------------

      def self.invoke(args)
        options = get_options(args)
        limit = (! options.patterns.empty?)
        Bgo::Application::PluginManager.plugins.values.sort { |a,b|
            a.name <=> b.name }.each do |p|
          next if limit && (options.patterns.select{|pat| p.name =~ pat}.empty?)
          puts p.name
        end
      end

      def self.get_options(args)
        options = OpenStruct.new
        options.patterns = []

        args.each do |arg| 
          pat = arg.gsub('*','.*').gsub('?','.?')
          options.patterns << /^#{pat}$/ 
        end

        return options
      end

    end

  end
end

