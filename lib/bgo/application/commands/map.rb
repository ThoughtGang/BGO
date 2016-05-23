#!/usr/bin/env ruby
# :title: Bgo::Commands::ProcessMap
=begin rdoc
BGO command to list and examine Map objects in a Process

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/map'

module Bgo
  module Commands

=begin rdoc
A command to show maps in a process.
=end
    class ProcessMapCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      end_pipeline
      summary 'List or view BGO Map objects in a Process'
      usage "#{Commands.data_model_usage} [-r num] [-acfiloPrRsvx] OBJPATH [...]"
      help "List/View Process Map objects in a Project or from STDIN.
Category: porcelain

Options:
  -a, --arch-info      Show architecture information for Map
  -b, --blocks         Show blocks
  -c, --comment        Show Map comment
  -C, --current        Show current Revision for Map
  -f, --flags          Show Map flags [default 'rw-']
  -i, --image          Show ident of Image being mapped
  -l, --list           List all Maps in Process
  -o, --offset         Show offset of Map in Image
  -P, --process        Show ident of Process containing Map
  -r, --revision num   Show contents for specified revision, not current
  -R, --raw            Output the raw binary contents of Map
  -s, --size           Show size of Map
  -v, --vma            Show Map load address (Virtual Memory Address) [default]
  -x, --hexdump        Output a hexdump of contents of Map
  --full               Produce detailed output
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}
Note: The --stdout option has no effect in this command.
      
OBJPATH is the object path of either a Process object or a Map object. If a 
Process object, all Maps in the Process will be listed.

The -r argument can be used to specify a revision of the Map contents for the
-R or -x options.

Examples:
  # List idents of all maps in Process 999
  bgo map process/999
  # List details for Map at VMA 0x8040100 in Process 1000
  bgo map --full process/1000/map/0x8040100
  # Hexdump of the contents of Revision 2 of Map 0x1000 in Process 999
  bgo map -r 2 -x process/999/map/0x1000

See also: map-create, map-delete, map-edit, process
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          obj = state.item_at_obj_path ident
          if obj.kind_of? Bgo::Process
            list_maps(obj, options)
            next
          elsif not obj.kind_of? Bgo::Map
            $stderr.puts "Not a Bgo::Map object: #{ident}"
          end

          if options.list_maps
            list_map obj, options
            next
          end

          show_vma(obj, options) if options.show_vma
          show_process(obj.parent_obj, options) if options.show_process
          show_ident(obj, options) if options.show_ident
          show_image(obj, options) if options.show_image
          show_offset(obj, options) if options.show_offset
          show_size(obj, options) if options.show_size
          show_flags(obj, options) if options.show_flags
          show_arch_info(obj, options) if options.show_arch_info
          show_comment(obj, options) if options.show_comment
          show_current_revision(obj, options) if options.show_curr_revision
          show_blocks(obj, options) if options.show_blocks
          show_hex_contents(obj, options) if options.show_hex
          show_raw_contents(obj, options) if options.show_raw
        end

        true
      end

      def self.get_options(args)
        options = super

        options.revision = nil
        options.idents = []

        options.show_arch_info = false
        options.show_blocks = false
        options.show_comment = false
        options.show_curr_revision = false
        options.show_flags = false
        options.show_process = false
        options.show_ident = false
        options.show_image = false
        options.show_offset = false
        options.show_size = false
        options.show_vma = false
        options.show_raw = false
        options.show_hex = false

        options.details = false
        options.list_maps = false

        opts = OptionParser.new do |opts|

          opts.on( '-a', '--arch-info' ) { options.show_arch_info = true }
          opts.on( '-b', '--blocks' ) { options.show_blocks = true }
          opts.on( '-c', '--comment' ) { options.show_comment = true }
          opts.on( '-C', '--current' ) { options.show_curr_revision = true }
          opts.on( '-f', '--flags' ) { options.show_flags = true }
          opts.on( '-i', '--ident' ) { options.show_ident = true }
          opts.on( '-I', '--image' ) { options.show_image = true }
          opts.on( '-o', '--offset' ) { options.show_offset = true }
          opts.on( '-P', '--process' ) { options.show_process = true }
          opts.on( '-r', '--revision int' ) {|n| options.revision = Integer(n)}
          opts.on( '-R', '--raw' ) { options.show_raw = true }
          opts.on( '-s', '--size' ) { options.show_size = true }
          opts.on( '-v', '--vma' ) { options.show_vma = true }
          opts.on( '-x', '--hexdump' ) { options.show_hex = true }
          opts.on( '-l', '--list' ) { options.list_maps = true }
          opts.on( '--full' ) { options.show_size = options.show_offset = true
            options.show_process = options.show_image = true
            options.show_flags = options.show_vma = true
            options.show_arch_info = options.show_comment = true
            options.show_ident = true
            options.show_curr_revision = options.details = true }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1
        while args.length > 0
          options.idents << args.shift
        end

        select_show_full(options) if not show_option_selected(options)

        return options
      end

      def self.show_option_selected(options)
        options.show_flags || options.show_offset || options.show_size || 
        options.show_vma || options.show_image || options.show_process ||
        options.show_comment || options.show_arch_info || options.show_raw ||
        options.show_hex || options.show_curr_revision || options.show_ident
      end

      def self.select_show_full(options)
        options.show_flags = options.show_offset = options.show_size = true
        options.show_vma = options.show_arch_info = options.show_ident = true
      end

      def self.show_flags(m, options)
        puts "#{options.details ? 'Flags: ' : ''}#{m.flags_str}"
      end

      def self.show_ident(m, options)
        puts "#{options.details ? 'Object Path: ' : ''}#{m.obj_path}"
      end

      def self.show_vma(m, options)
        if options.details
          puts "VMA: 0x%X 0%o %d" % [m.start_addr, m.start_addr, m.start_addr]
        else
          puts "0x%0X" % m.start_addr
        end
      end

      def self.show_offset(m, options)
        if options.details
          puts "Offset: 0x%X 0%o %d" % [m.offset, m.offset, m.offset]
        else
          puts "0x%0X" % m.offset
        end
      end

      def self.show_size(m, options)
        if options.details
          puts "Size: 0x%X 0%o %d" % [m.size, m.size, m.size]
        else
          puts "0x%0X" % m.size
        end
      end

      def self.show_process(p, options)
        puts "#{options.details ? 'Process: ' : ''}#{p.ident}"
      end

      def self.show_image(m, options)
        puts "#{options.details ? 'Image: ' : ''}#{m.base_image.ident}"
      end

      def self.show_arch_info(m, options)
        puts "#{options.details ? 'Arch Info: ' : ''}#{m.arch_info}"
      end

      def self.show_comment(m, options)
        txt = m.comment ? m.comment.text : ''
        puts "#{options.details ? 'Comment: ' : ''}#{txt}"
      end

      def self.show_current_revision(m, options)
        puts "#{options.details ? 'Current Revision: ' : ''}#{m.revision}"
      end

      def self.show_blocks(m, options)
        puts "Blocks:"
        puts m.block.inspect
      end

      def self.show_raw_contents(m, options)
        $stdout.write m.contents(options.revision)
      end

      def self.show_hex_contents(m, options)
        puts "Contents:" if options.details
        idx = 0
        m.contents(options.revision).bytes.each do |byte|
          print "%08X:" % [idx] if (idx % 16 == 0)
          print " %02X" % byte
          idx += 1
          print "\n" if idx % 16 == 0
        end
        print "\n" if idx % 16 != 0
      end

      def self.list_maps(p, options)
        puts "Maps:" if options.details
        p.maps.each { |m| list_map(m, options) }
      end

      def self.list_map(obj, options)
        if obj.kind_of? Bgo::Map
          puts (options.details ? obj.inspect : obj.ident)
        else
          puts "Not a BGO Map: #{obj.class} #{obj.inspect}"
        end
      end

    end

  end
end

