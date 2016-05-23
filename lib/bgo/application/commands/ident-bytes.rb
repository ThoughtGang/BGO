#!/usr/bin/env ruby
# :title: Bgo::Commands::IdentBytes
=begin rdoc
BGO command to run an Ident plugin on binary input and write to STDOUT.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/plugin_mgr'

require 'bgo/ident'

module Bgo
  module Commands

=begin rdoc
A command to get ident string for a file or string
=end
    class IdentBytesCommand < Application::Command
# ----------------------------------------------------------------------
      disable_pipeline
      summary 'Identify type of a file or string'
      usage "[-abrx] [-f|j|m|M|s|t] [-u str] FILE"
      help "Generate a BGO Ident object for a File or String.
Category: porcelain

The Ident info for the specified file or buffer will be determined by one
or more plugins. If a plugin is specified with the -u option, it will be used; 
otherwise, all plugins implementing the IDENT_FILE interface will be
invoked. The -a option will cause the output of all plugins to be displayed;
otherwise, only the output with the highest confidence rating will be
displayed.

Options:
  -a, --all                 Show results for all ident plugins (implies -d)
  -b, --buffer              Treat STRING as a buffer of bytes
  -f, --full                Display the BGO Ident full field (default)
  -j, --json                Ouput BGO Ident object in JSON
  -m, --magic               Display the BGO Ident format ('magic') field
  -M, --mime-type           Display the BGO Ident mime (mime-type) field
  -r, --rating              Display confidence rating and name of plugin
  -s, --summary             Display the BGO Ident summary field
  -t, --content-type        Display the BGO Ident contents field
  -u, --use-plugin string   Specify plugin to use for :ident spec
  -x, --hex                 Input is in hexadecimal octets (e.g. 'CC FF 00 1F')

Only one of -f, -j, -m, -M, -s, and -t can be supplied.

The -r option can be used to display the confidence rating and name of the 
plugin that generated the Ident object. 

The -b option can be used to interpret STRING as a buffer instead of a filename.

Examples:
  bgo ident-bytes /tmp/a.out
  cat /tmp/a.out | bgo ident-bytes
  bgo ident-bytes -u Magic /tmp/a.out
  bgo ident-bytes -a /tmp/a.out
  bgo ident-bytes -b -x 23 21 2F 62 69 6E 2F 62 61 73 68 0A 65 78 69 74 0A
  # List all Ident plugins
  bgo plugin-specs -p ident

See also: ident, plugin-list, plugin-specs"
# ----------------------------------------------------------------------

      def self.invoke(args)
        options = get_options(args)

        if options.show_all
          display_all_idents(options)
          true
        end

        plugin = find_plugin(options)
        if ! plugin
          if options.plugin
            $stderr.puts "Could not find plugin '#{options.plugin}'"
          else
            $stderr.puts "No suitable plugin for ident #{options.inspect}"
          end
          return false
        end

        invoke_plugin(plugin, options)

        true
      end

      def self.find_plugin(options)
        options.plugin ?
            Bgo::Application::PluginManager.find(options.plugin) :
            Bgo::Application::PluginManager.fittest_providing(:ident, 
                                                             options.bytes,
                                                             options.path)
      end

      def self.display_all_idents(options)
        Bgo::Application::PluginManager.providing(:ident).sort { |a,b|
            a[0].name.to_s <=> b[0].name.to_s }.each do |p,score|
              invoke_plugin(p, options)
        end
      end

      def self.invoke_plugin(p, options)
        score = p.spec_rating(:ident, options.bytes, options.path)
        ident = p.spec_invoke(:ident, options.bytes, options.path)
        display_ident(ident, p.name, score, options)
      end

      def self.display_ident(ident, name, score, options)
        if options.json_output
          puts ident.to_json
          return
        end

        rating = options.show_rating ? "[%s|%02d] " % [name, score] : ''

        case options.ident_format
        when :magic
            data =  ident.format
        when :summary
            data = ident.summary
        when :contents
            data =  ident.contents.to_s
        when :mime
            data =  ident.mime
        else
            data = ident.full
        end

        puts rating + data.gsub(/\s/, ' ')
      end

      def self.get_options(args)
        options = super

        options.json_output = false
        options.hex_input = false
        options.plugin = nil

        options.ident_format = :full
        options.show_rating = false
        options.show_all = false        # show all matches (default: best)
        options.is_buffer = false       # is target a buffer

        opts = OptionParser.new do |opts|
          opts.on( '-a', '--all' ) { options.show_all = true 
                                     options.show_rating = true }
          opts.on( '-b', '--buffer' ) { options.is_buffer = true }
          opts.on( '-r', '--rating' ) { options.show_rating = true }
          opts.on( '-f', '--full' ) { options.ident_format = :full }
          opts.on( '-j', '--json' ) { options.json_output = true }
          opts.on( '-m', '--magic' ) { options.ident_format = :magic }
          opts.on( '-M', '--mime-type' ) { options.ident_format = :mime }
          opts.on( '-s', '--summary' ) { options.ident_format = :summary }
          opts.on( '-t', '--content-type' ) { options.ident_format = :contents }
          opts.on( '-u', '--use-plugin string' ) { |str| options.plugin = str }
          opts.on( '-x', '--hex' ) { options.hex_input = true }
        end

        opts.parse!(args)

        if options.is_buffer
          options.bytes = args.join(' ')
          options.path = ''
        else
          options.bytes = ARGF.read
          options.path = ARGF.filename
          options.path = '' if options.path == '-'
        end

        if options.hex_input
          # convert contents from hex-dump to binary
          options.bytes = options.bytes.split(/\s/).map { |s| s.to_i(16) 
                                                        }.pack('c*')
        end

        return options
      end

    end

  end
end
