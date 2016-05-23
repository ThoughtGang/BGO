#!/usr/bin/env ruby
# :title: Bgo::Commands::Address
=begin rdoc
BGO command to list and examine Address objects

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/standard_options'

# TODO: contents, names, references.

module Bgo
  module Commands

=begin rdoc
A command to show Address objects.
=end
    class AddressCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      end_pipeline
      summary 'List or view BGO Address objects'
      usage "#{Commands.data_model_usage} [-clorstx] [--full] OBJPATH [...]"
      help "List/View Address objects in a Project or from STDIN.
Category: porcelain

Options:
  -c, --comment        Show Address comment
  -i, --ident          Show Address ident
  -l, --list           List all Address in TargetFile or Process
  -o, --offset         Show offset of Address in TargetFile or Process
  -r, --raw            Output the raw binary contents of Address
  -s, --size           Show size of Address
  -t, --content-type   Show type of Address Contents (code|data|unknown)
  -v, --vma            Show load address (VMA) of Address
  -x, --hexdump        Output a hexdump of contents of Address
  --full               Produce detailed output
#{Commands.standard_options_help}
#{Commands.data_model_options_help}
      
The -x option can be used to display a hexdump of the contents of the Address.

#{Commands.data_model_help}
Note: The --stdout option has no effect in this command.

OBJPATH is the object path of an Address object, or of a Process, TargetFile,
Map, or Section containing the Address.

Examples:
  # List all Address objects in TargetFile a.out
  bgo address -F /tmp/a.out
  # Show Address 0x1000 in TargetFile a.out
  bgo address --full file/^tmp^a.out/0x1000
  bgo address --full file/^tmp^a.out/address/0x1000
  # Show hexdump of Address 0x200 in TargetFile a.out
  bgo address -x file/^tmp^a.out/0x200

See also: address-delete, address-edit, file-address-create, 
          process-address-create
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          obj = state.item_at_obj_path ident
          if obj.respond_to? :addresses
            list_addresses(obj, options)
            next
          elsif not obj.kind_of? Bgo::Address
            $stderr.puts "Not a Bgo::Address object: #{ident}"
            next
          end

          options.list_addresses ? list_address(obj, options) : \
                                   show_address(obj, options)
        end

        true
      end

      def self.get_options(args)
        options = super

        options.idents = []

        options.show_ident = false
        options.show_comment = false
        options.show_ctype = false
        options.show_vma = false
        options.show_offset = false
        options.show_raw = false
        options.show_size = false
        options.show_hex = false
        options.details = false
        options.list_addresses = false


        opts = OptionParser.new do |opts|

          opts.on( '-c', '--comment' ) { options.show_comment = true }
          opts.on( '-i', '--ident' ) { options.show_ident = true }
          opts.on( '-o', '--offset' ) { options.show_offset = true }
          opts.on( '-r', '--raw' ) { options.show_raw = true }
          opts.on( '-s', '--size' ) { options.show_size = true }
          opts.on( '-t', '--content-type' ) { options.show_ctype = true }
          opts.on( '-v', '--vma' ) { options.show_vma = true }
          opts.on( '-x', '--hexdump' ) { options.show_hex = true }
          opts.on( '-l', '--list' ) { options.list_addresses = true }
          opts.on( '--full' ) { options.show_size = options.show_offset = true
            options.show_vma = options.show_ctype = options.show_ident = true
            options.show_comment = options.details = true }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1
        while args.length > 0
          options.idents << args.shift
        end

        options.show_vma = true if not show_option_selected(options)
        show_full(options) if not show_option_selected(options)

        return options
      end

      def self.show_option_selected(options)
        options.show_ident || options.show_comment || options.show_ctype ||
        options.show_vma || options.show_offset || options.show_raw ||
        options.show_size || options.show_hex
      end

      def self.show_full(options)
        options.show_ident = options.show_comment = options.show_ctype = true
        options.show_vma = options.show_offset = options.show_size = true
      end

      def self.show_address(a, options)
        show_ident(a, options) if options.show_ident
        show_vma(a, options) if options.show_vma
        show_offset(a, options) if options.show_offset
        show_size(a, options) if options.show_size
        show_ctype(a, options) if options.show_ctype
        show_comment(a, options) if options.show_comment
        show_hex_contents(a, options) if options.show_hex
        show_raw_contents(a, options) if options.show_raw
      end

      def self.show_option_selected(options)
        options.show_offset || options.show_size || options.show_section || 
        options.show_arch_info || options.show_comment || options.show_ctype ||
        options.show_raw || options.show_hex
      end

      def self.show_ident(a, options)
        puts "#{options.details ? 'Object Path: ' : ''}#{a.obj_path}"
      end

      def self.show_vma(a, options)
        if options.details
          puts "VMA: 0x%X 0%o %d" % [a.vma, a.vma, a.vma]
        else
          puts "0x%0X" % a.vma
        end
      end

      def self.show_offset(a, options)
        if options.details
          puts "Offset: 0x%X 0%o %d" % [a.offset, a.offset, a.offset]
        else
          puts "0x%0X" % a.offset
        end
      end

      def self.show_size(a, options)
        if options.details
          puts "Size: 0x%X 0%o %d" % [a.size, a.size, a.size]
        else
          puts "0x%0X" % a.size
        end
      end

      def self.show_ctype(a, options)
        puts "#{options.details ? 'Content-tye: ' : ''}#{a.content_type}"
      end

      def self.show_comment(a, options)
        txt = a.comment ? a.comment.text : ''
        puts "#{options.details ? 'Comment: ' : ''}#{txt}"
      end

      def self.show_raw_contents(a, options)
        $stdout.write a.bytes
      end

      def self.show_hex_contents(a, options)
        puts "Contents:" if options.details
        idx = 0
        a.bytes.each do |byte| 
          print "%08X:" % [idx] if (idx % 16 == 0)
          print " %02X" % byte
          idx += 1
          print "\n" if idx % 16 == 0
        end
        print "\n" if idx % 16 != 0
      end

      def self.list_addresses(obj, options)
        puts "Addresses:" if options.details
        obj.addresses.each { |addr| list_address(addr, options) }
      end

      def self.list_address(obj, options)
        if obj.kind_of? Bgo::Address
          puts (options.details ? obj.inspect : obj.ident)
        else
          puts "Not a BGO Address: #{obj.class} #{obj.inspect}"
        end
      end

    end

  end
end
