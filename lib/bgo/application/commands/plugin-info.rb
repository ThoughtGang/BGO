#!/usr/bin/env ruby
# :title: Bgo::Commands::PluginInfo
=begin rdoc
BGO command to list plugin details

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/plugin_mgr'

module Bgo
  module Commands

=begin rdoc
A command to list plugin details
=end
    class PluginInfoCommand < Application::Command
# ----------------------------------------------------------------------
      disable_pipeline
      summary 'Print Plugin info'
      usage 'PLUGIN'
      help 'This command prints details of a specific plugin to STDOUT.
Category: porcelain

Examples:
  # Show info for Magic plugin
  bgo plugin-info Magic

  # Show info for Bfd plugin
  bgo plugin-info Bfd

See also: plugin-dirs, plugin-eval, plugin-help, plugin-list, plugin-specs
'
# ----------------------------------------------------------------------

      def self.invoke(args)
        if args.count == 0
          puts "Plugin name is required"
          return false
        end

        plugin_name = args[0]
        found = false

        Bgo::Application::PluginManager.plugins.values.sort { |a,b|
            a.name <=> b.name }.each do |p|
          next if p.name != plugin_name
          found = true

          puts "Name: #{p.name}"
          puts "Version: #{p.version}"
          puts "Canon-Name: #{p.canon_name}"
          puts "Author: #{p.author}"
          puts "License: #{p.license}"
          puts "Description: #{p.description}"

          puts "\nMethod Specifications:"
          p.specs.each{ |name, s| print_spec(name, s) }

          puts "\nApi Methods:"
          p.api(true).each { |name, m| print_api(name, m) }

          puts "\nDependencies:"
          p.class.dependencies.each { |dep| puts "\t#{depends_string(dep)}" }
        end

        $stderr.puts "Plugin '#{plugin_name} ' not found." if ! found
      end

      def self.depends_string(dep)
        "#{dep[:name]} #{dep[:op]} #{dep[:version]}"
      end

      def self.print_spec(name, mspec)
        spec = Bgo::Application::PluginManager.specification(name)
        puts "\t%s: %s [%s]" % [name, spec.prototype, mspec.symbol]
      end

      def self.print_api(name, meth)
        descr = meth.description
        puts "\t# " + descr if descr && (! descr.empty?)
        puts "\t%s(%s) -> %s" % [name, meth.arguments.join(', '), 
                                 meth.return_value]
      end

    end

  end
end

