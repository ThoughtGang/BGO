#!/usr/bin/env ruby
# :title: Bgo::Commands::DisasmBytes
=begin rdoc
BGO command to disassemble bytes in a file or string and write the results to
STDOUT

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/plugin_mgr'
require 'bgo/application/commands/shared/plugin'

require 'bgo/disasm'
require 'bgo/packet'

module Bgo
  module Commands

=begin rdoc
A command to disassemble arbitrary bytes in a file or buffer
=end
    class DisasmBytesCommand < Application::Command
# ----------------------------------------------------------------------
      disable_pipeline
      summary 'Disassemble a file or string using a Disassembler plugin.'
      usage "[-bBchLrx] [-oes num] [-d str] #{Commands.plugin_usage} STRING"
      help "Disassemble bytes in a File or buffer.
Category: porcelain

Options:
  -a, --arch string         Architecture string for target
  -b, --buffer              Treat STRING as a buffer of bytes
  -B, --big-endian          Architecture is big-endian
  -c, --cflow               Use control-flow instead of linear disasm
  -d, --delim string        Use 'string' as field delimiter
  -e, --entry int           Entry point for control-flow disasm
  -h, --header              Display a header above output
  -j, --json                Ouput BGO Ident object in JSON
  -L, --little-endian       Architecture is little-endian
  -o, --offset int          Offset into to file of code segment (default: 0)
  -s, --size int            # of bytes from offset to disasm (default: to end)
  -x, --hex                 Input is in hexadecimal octets (e.g. 'CC FF 00 1F')
#{Commands.plugin_options_help}

The -b option can be used to interpret STRING as a buffer instead of a filename.

The -a option can be used to specify the architecture of the target if it 
cannot be autodetected by any plugin. Use the 'bgo info' command to list
supported architectures. Note that -B and -L can be used to specify the
endianness of the target if the architecture supports multiple endian types
(e.g. ARM).

To print the plugin name and confidence score to STDERR, set the 
BGO_PLUGIN_DEBUG environment variable to 1.

Examples:
  bgo disasm-bytes /tmp/a.out
  cat /tmp/a.out | bgo disasm-bytes
  bgo disasm-bytes -u BFD /tmp/a.out
  bgo disasm-bytes -a /tmp/a.out
  bgo disasm-bytes -h -d '|' /tmp/a.out
  bgo disasm-bytes -u Opdis -d '|' -b -x  90 90 90
  # List all Disassembler plugins
  bgo plugin-specs -p disassemble 
  # List all supported architectures
  bgo info -a

See also: disasm, info, load-bytes, parse-bytes, plugin-list, plugin-specs"
# ----------------------------------------------------------------------

      def self.invoke(args)
        options = get_options(args)

        pkt = gen_target(options)
        tgt = pkt.sections.first
        task = gen_disasm_task(tgt, options)

        h = invoke_disasm(task, tgt, options)
        display_instructions(h, options)

        true
      end

      def self.invoke_disasm(task, target, options)
        args = [task, target]
        plugin = Commands.plugin_for_spec(:disassemble, options.plugin, *args)
        if ! plugin
          $stderr.puts "Unable to find a plugin supporting :disassemble"
          return {}
        end

        plugin.spec_invoke(:disassemble, *args)
      end

      def self.gen_target(options)
        img = Bgo::Image.new(options.bytes)
        pkt = Bgo::Packet.new('anonymous bytes', img)
        ai = ArchInfo.new(options.arch, Bgo::ArchInfo::UNKNOWN, options.endian)

        off = options.offset || 0
        sz = options.size || (img.size - off)
        pkt.add_section('.text', off, sz)

        pkt
      end

      def self.gen_disasm_task(tgt, options)
        options.plugin_opts = {} if (! options.plugin_opts.kind_of? Hash)
        # TODO: support disasm tasks provided by plugins
        if options.cflow
          addr = options.start_offset || options.offset || 0
          # start_addr, visited_addr, insiders=nil, output={}, handler=nil, opts
          Bgo::CflowDisasmTask.new(addr, {}, nil, {}, nil, options.plugin_opts)
        else
          range = options.size ? (options.offset || 0) + options.size : nil
          Bgo::LinearDisasmTask.new(0, range, {}, nil, options.plugin_opts)
        end
      end

      def self.display_instructions(h, options)
        if options.json_output
          puts h.to_json
          return
        end

        h.keys.sort.each do |k|
          addr = h[k]
          # TODO: more intelligent way of formatting instructions
          puts "%08X:%c%s%s" % [addr.vma, options.delim, addr.hexdump, 
                                (addr.code?) ? 
                                options.delim + addr.contents.ascii : '']
        end
      end

      def self.get_options(args)
        options = super

        options.json_output = false
        options.hex_input = false
        options.is_buffer = false       # is target a buffer
        options.show_header = false
        options.cflow = false
        options.path = nil

        options.offset = 0
        options.size = nil
        options.entry = nil
        options.arch = nil
        options.endian = Bgo::ArchInfo::ENDIAN_LITTLE
        options.delim = "\t"

        opts = OptionParser.new do |opts|
          opts.on( '-a', '--arch string' ) { |str| options.arch = str }
          opts.on( '-B', '--big-endian' ) { 
            options.endian = Bgo::ArchInfo::ENDIAN_BIG }
          opts.on( '-L', '--little-endian' ) {
            options.endian = Bgo::ArchInfo::ENDIAN_LITTLE }

          opts.on( '-b', '--buffer' ) { options.is_buffer = true }
          opts.on( '-c', '--cflow' ) { options.cflow = true }
          opts.on( '-d', '--delim char' ) { |c| options.delim = c }
          opts.on( '-e', '--entry int' ) { |n| options.entry = Integer(n) }
          opts.on( '-j', '--json' ) { options.json_output = true }
          opts.on( '-o', '--offset int' ) { |n| options.offset = Integer(n) }
          opts.on( '-s', '--size int' ) { |n| options.size = Integer(n) }
          opts.on( '-x', '--hex' ) { options.hex_input = true }

          Commands.plugin_options(options, opts)
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
                                                        }.pack('C*')
        end

        return options
      end

    end

  end
end
