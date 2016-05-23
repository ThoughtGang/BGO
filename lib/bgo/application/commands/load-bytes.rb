#!/usr/bin/env ruby
# :title: Bgo::Commands::LoadBytes
=begin rdoc
BGO command to create Process Maps from a file and and write structure to 
STDOUT.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

# TODO: REFACTOR: this has a lot in common with parse-bytes

require 'bgo/application/command'
require 'bgo/application/plugin_mgr'

require 'bgo/ident'

module Bgo
  module Commands

=begin rdoc
A command to create Process Maps from a File object.
=end
    class LoadBytesCommand < Application::Command
# ----------------------------------------------------------------------
      disable_pipeline
      summary 'Create Maps from a file or string using a Loader plugin.'
      usage "[-bdjhrx] [-os num] [-du str] STRING"
      help "Create BGO Map objects from contents of a File or buffer.
Category: porcelain

Options:
  -b, --buffer              Treat STRING as a buffer of bytes
  -d, --delim string        Use 'string' as field delimiter
  -h, --header              Display a header above output
  -j, --json                Ouput BGO Ident object in JSON
  -o, --offset              Offset of loadable image in file or string
  -r, --rating              Display confidence rating and name of plugin
  -s, --size                Number of bytes in loadable image
  -u, --use-plugin string   Specify plugin to use for :ident spec
  -x, --hex                 Input is in hexadecimal octets (e.g. 'CC FF 00 1F')


The -r option can be used to display the confidence rating and name of the 
plugin that generated the Map objects. 

The -b option can be used to interpret STRING as a buffer instead of a filename.

Examples:
  bgo load-bytes /tmp/a.out
  cat /tmp/a.out | bgo load-bytes
  bgo load-bytes -u BFD /tmp/a.out
  bgo load-bytes -a /tmp/a.out
  bgo load-bytes -b -x 23 21 2F 62 69 6E 2F 62 61 73 68 0A 65 78 69 74 0A
  bgo load-bytes -h -d '|' /tmp/a.out
  # List all Loader plugins
  bgo plugin-specs -p load_file

See also: load, parse-bytes, plugin-list, plugin-specs"
# ----------------------------------------------------------------------

      def self.invoke(args)
        options = get_options(args)
        p = Bgo::Process.new( 1000, options.path )
        f = gen_file(options)
        # TODO: support plugin options
        h = {}

        plugin = find_plugin(options.plugin, p, f, h)
        if ! plugin
          if options.plugin
            $stderr.puts "Could not find plugin '#{options.plugin}'"
          else
            $stderr.puts "No suitable plugin for ident #{options.inspect}"
          end
          return false
        end

        score = plugin.spec_rating(:load_file, p, f, h)
        rv = plugin.spec_invoke(:load_file, p, f, h)

        display_process(p, plugin.name, score, options)

        true
      end

      def self.find_plugin(name, p, f, opts={})
        name ? Bgo::Application::PluginManager.find(name) :
               Bgo::Application::PluginManager.fittest_providing(:load_file, 
                                                                 p, f, opts)
      end

      def self.gen_file(options)
        path = options.path
        img = Bgo::Image.new(options.bytes)
        Bgo::TargetFile.new File.basename(path), path, img, options.offset,
                            options.size
      end

      def self.display_process(p, name, score, options)
        if options.json_output
          puts p.maps.to_json
          return
        end

        puts "[%s|%02d] " % [name, score] if options.show_rating

        puts [ "flags", "size", "start", "end", "offset", "arch_info" 
             ].join(options.delim) if options.show_header
        p.maps.each do |m|
          ai = m.arch_info ? m.arch_info : Bgo::Archinfo.unknown
          arr = [ m.flags_str, m.size.to_i, "0x%08X" % m.start_addr, 
                  "0x%08X" % (m.start_addr + m.size - 1),
                  "0x%04X" % m.image_offset, ai.to_s ]
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
