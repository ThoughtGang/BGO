#!/usr/bin/env ruby
# :title: Bgo::Commands::ParseBytes
=begin rdoc
BGO command to parse a file into sections and write structure to STDOUT.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

# TODO: files without sections, e.g. data files?
#       file header information?

require 'bgo/application/command'
require 'bgo/application/plugin_mgr'

require 'bgo/ident'

module Bgo
  module Commands

=begin rdoc
A command to create sections in a File object.
=end
    class ParseBytesCommand < Application::Command
# ----------------------------------------------------------------------
      disable_pipeline
      summary 'Parse a file or string using a Loader plugin.'
      usage "[-bdjhrx] [-os num] [-du str] STRING"
      help "Parse a File or buffer.
Category: porcelain

Options:
  -b, --buffer              Treat STRING as a buffer of bytes
  -d, --delim string        Use 'string' as field delimiter
  -h, --header              Display a header above output
  -j, --json                Ouput BGO Ident object in JSON
  -o, --offset              Offset into to file to begin parsing at (default: 0)
  -r, --rating              Display confidence rating and name of plugin
  -s, --size                Number of bytes in file to parse (default: to end)
  -u, --use-plugin string   Specify plugin to use for :ident spec
  -x, --hex                 Input is in hexadecimal octets (e.g. 'CC FF 00 1F')


The -r option can be used to display the confidence rating and name of the 
plugin that generated the Section objects. 

The -b option can be used to interpret STRING as a buffer instead of a filename.

Examples:
  bgo parse-bytes /tmp/a.out
  cat /tmp/a.out | bgo parse-bytes
  bgo parse-bytes -u BFD /tmp/a.out
  bgo parse-bytes -a /tmp/a.out
  bgo parse-bytes -b -x 23 21 2F 62 69 6E 2F 62 61 73 68 0A 65 78 69 74 0A
  bgo parse-bytes -h -d '|' /tmp/a.out
  # List all Parser plugins
  bgo plugin-specs -p parse_file

See also: load-bytes, parse, plugin-list, plugin-specs"
# ----------------------------------------------------------------------

      def self.invoke(args)
        options = get_options(args)
        f = gen_file(options)
        # TODO: support plugin options
        h = {}

        plugin = find_plugin(options.plugin, f, h)
        if ! plugin
          if options.plugin
            $stderr.puts "Could not find plugin '#{options.plugin}'"
          else
            $stderr.puts "No suitable plugin for ident #{options.inspect}"
          end
          return false
        end

        score = plugin.spec_rating(:parse_file, f, h)
        rv = plugin.spec_invoke(:parse_file, f, h)

        display_file(f, plugin.name, score, options)

        true
      end

      def self.find_plugin(name, f, opts={})
        name ? Bgo::Application::PluginManager.find(name) :
               Bgo::Application::PluginManager.fittest_providing(:parse_file, 
                                                                 f, opts)
      end

      def self.gen_file(options)
        path = options.path
        img = Bgo::Image.new(options.bytes)
        Bgo::TargetFile.new File.basename(path), path, img, options.offset,
                            options.size
      end

      def self.display_file(f, name, score, options)
        if options.json_output
          puts f.sections.to_json
          return
        end

        puts "[%s|%02d] " % [name, score] if options.show_rating

        puts [ "ident", "name", "flags", "size", "start", "end" 
             ].join(options.delim) if options.show_header
        f.sections_sorted.each do |s|
          arr = [ s.ident, s.name, s.flags_str, s.size.to_i, 
                  "0x%04X" % s.file_offset, 
                  "0x%04X" % (s.file_offset + s.size - 1) ]
          puts arr.join(options.delim)
        end
      end

      def self.get_options(args)
        options = super

        options.json_output = false
        options.hex_input = false
        options.plugin = nil
        options.path = nil

        options.show_rating = false
        options.show_header = false
        options.is_buffer = false       # is target a buffer
        options.delim = "\t"
        options.offset = 0
        options.size = nil

        opts = OptionParser.new do |opts|
          opts.on( '-b', '--buffer' ) { options.is_buffer = true }
          opts.on( '-d', '--delim char' ) { |c| options.delim = c }
          opts.on( '-h', '--header' ) { options.show_header = true }
          opts.on( '-j', '--json' ) { options.json_output = true }
          opts.on( '-o', '--offset int' ) { |n| options.offset = Integer(n) }
          opts.on( '-r', '--rating' ) { options.show_rating = true }
          opts.on( '-s', '--size int' ) { |n| options.size = Integer(n) }
          opts.on( '-u', '--use-plugin string' ) { |str| options.plugin = str }
          opts.on( '-x', '--hex' ) { options.hex_input = true }
        end

        opts.parse!(args)

        if options.is_buffer
          options.bytes = args.join(' ')
        else
          options.bytes = ARGF.read
          options.path ||= ARGF.filename if ARGF.filename != '-'
        end
        options.path ||= 'unknown'

        if options.hex_input
          # convert contents from hex dump to binary
          options.bytes = options.bytes.split(/\s/).map { |s| s.to_i(16) 
                                                        }.pack('c*')
        end

        return options
      end

    end

  end
end
