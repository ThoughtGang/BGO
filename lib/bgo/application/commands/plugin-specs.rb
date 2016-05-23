#!/usr/bin/env ruby
# :title: Bgo::Commands::PluginSpecs
=begin rdoc
BGO command to list defined plugin specifications

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/plugin_mgr'

module Bgo
  module Commands

=begin rdoc
A command to list plugin specifications
=end
    class PluginSpecsCommand < Application::Command
# ----------------------------------------------------------------------
      disable_pipeline
      summary 'List plugin specifications'
      usage '[-p] [pattern]'
      help 'This command lists defined plugin specifications. 
Category: porcelain

The list can be narrowed using globs.

Options:
  -p                Show plugins that implement specification
  pattern           A Plugin name to match, using * and ? for globbing.

Examples:
  # List all plugin specifications
  bgo plugin-speccs

  # List all plugin specifications matching the pattern "dis*"
  bgo plugin-specs \'dis*\'

  # List all plugin specifications matching the pattern "*code*"
  bgo plugin-specs \'*code*\'

See also: plugin-dirs, plugin-eval, plugin-help, plugin-info, plugin-list
'
# ----------------------------------------------------------------------

      def self.invoke(args)
        options = get_options(args)
        limit = (! options.patterns.empty?)
        Bgo::Application::PluginManager.specifications.values.sort { |a,b|
            a.name.to_s <=> b.name.to_s }.each do |s|
          next if limit && \
                  (options.patterns.select{|pat| s.name.to_s =~ pat}.empty?)
          puts "%s\t%s" % [s.name.to_s, s.prototype]
          list_plugins_providing(s) if options.show_plugins
        end
      end

      def self.list_plugins_providing(spec)
        Bgo::Application::PluginManager.providing(spec.name).sort { |a,b|
            a[0].name.to_s <=> b[0].name.to_s }.each do |p,score|
          puts "\t%s (%d)" % [p.name, score]
        end
      end

      def self.get_options(args)
        options = OpenStruct.new
        options.show_plugins = false
        options.patterns = []

        opts = OptionParser.new do |opts|
          opts.on( '-p', '--show-plugins' ) { options.show_plugins = true }
        end

        opts.parse!(args)

        args.each do |arg|
          pat = arg.gsub('*','.*').gsub('?','.?')
          options.patterns << /^#{pat}$/ 
        end

        return options
      end

    end

  end
end

