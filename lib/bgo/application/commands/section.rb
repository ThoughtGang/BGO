#!/usr/bin/env ruby
# :title: Bgo::Commands::FileSection
=begin rdoc
BGO command to list and examine Section objects in a TargetFile

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/model_item'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/section'

module Bgo
  module Commands

=begin rdoc
A command to show sections in a file.
=end
    class FileSectionCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      end_pipeline
      summary 'List or view BGO Section objects in a TargetFile'
      usage "#{Commands.data_model_usage} [-acfFiIlnorsx] [--full] OBJPATH [...]"
      help "List/View TargetFile Section objects in a Project or from STDIN.
Category: porcelain

Options:
  -a, --arch-info      Show architecture information for Section
  -c, --comment        Show Section comment
  -f, --flags          Show Section flags [default 'rw-']
  -F, --file           Show ident of TargetFile containing Section
  -i, --ident          Show Section ident
  -I, --image          Show ident of Image containing Section 
  -l, --list           List all Sections in TargetFile
  -n, --name           Show Section name
  -o, --offset         Show offset of Section in TargetFile
  -r, --raw            Output the raw binary contents of Section
  -s, --size           Show size of Section
  -x, --hexdump        Output a hexdump of contents of Section
  --full               Produce detailed output
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}
Note: The --stdout option has no effect in this command.
      
OBJPATH is the object path of either a File object or a Section object. If a 
File object, all Section in the File will be listed.

Examples:
  # List idents of all sections in TargetFile /tmp/a.out
  bgo section file/tmp^a.out
  # List all sections in TargetFile /tmp/a.out
  bgo section --full file/^tmp^a.out
  # Display Section 1 in TargetFile /tmp/a.out
  bgo section --full file/tmp^a.out/section/1
  # Display hexdump of Section 1 bytes in TargetFile /tmp/a.out
  bgo section -x /tmp^a.out/section/1

See also: file, section-create, section-delete, section-edit
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          obj = state.item_at_obj_path ident
          if obj.kind_of? Bgo::TargetFile
            list_sections(obj, options)
            next
          elsif not obj.kind_of? Bgo::Section
            $stderr.puts "Not a Bgo::Section object: #{ident}"
            next
          end

          if options.list_sections
            list_section(obj, options)
            next
          end

          # note: size, offset in hex and decimal
          show_ident(obj, options) if options.show_ident
          show_name(obj, options) if options.show_name
          show_file(obj.parent_obj, options) if options.show_file
          show_image(obj.parent_obj, options) if options.show_image
          show_offset(obj, options) if options.show_offset
          show_size(obj, options) if options.show_size
          show_flags(obj, options) if options.show_flags
          show_arch_info(obj, options) if options.show_arch_info
          show_comment(obj, options) if options.show_comment
          show_hex_contents(obj, options) if options.show_hex
          show_raw_contents(obj, options) if options.show_raw
        end

        true
      end

      def self.get_options(args)
        options = super

        options.idents = []

        options.show_arch_info = false
        options.show_comment = false
        options.show_flags = false
        options.show_file = false
        options.show_ident = false
        options.show_image = false
        options.show_name = false
        options.show_offset = false
        options.show_raw = false
        options.show_size = false
        options.show_hex = false

        options.details = false
        options.list_sections = false

        opts = OptionParser.new do |opts|

          opts.on( '-a', '--arch-info' ) { options.show_arch_info = true }
          opts.on( '-c', '--comment' ) { options.show_comment = true }
          opts.on( '-f', '--flags' ) { options.show_flags = true }
          opts.on( '-F', '--file' ) { options.show_file = true }
          opts.on( '-i', '--ident' ) { options.show_ident = true }
          opts.on( '-I', '--image' ) { options.show_image = true }
          opts.on( '-n', '--name' ) { options.show_name = true }
          opts.on( '-o', '--offset' ) { options.show_offset = true }
          opts.on( '-r', '--raw' ) { options.show_raw = true }
          opts.on( '-s', '--size' ) { options.show_size = true }
          opts.on( '-x', '--hexdump' ) { options.show_hex = true }
          opts.on( '-l', '--list' ) { options.list_sections = true }
          opts.on( '--full' ) { options.show_ident = options.show_image = true
            options.show_file = options.show_name = true
            options.show_arch_info = options.show_flags = true
            options.show_comment = options.show_offset = true
            options.show_size = options.details = true }

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
        options.show_ident || options.show_comment || options.show_raw ||
        options.show_hex || options.show_name || options.show_arch_info ||
        options.show_flags || options.show_offset || options.show_size || 
        options.show_image || options.show_file 
      end

      def self.select_show_full(options)
        options.show_ident = options.show_name = options.show_arch_info = true
        options.show_flags = options.show_offset = options.show_size = true
      end

      def self.show_ident(s, options)
        puts "#{options.details ? 'Object Path: ' : ''}#{s.obj_path}" 
      end

      def self.show_flags(s, options)
        puts "#{options.details ? 'Flags: ' : ''}#{s.flags_str}"
      end

      def self.show_name(s, options)
        puts "#{options.details ? 'Name: ' : ''}#{s.name}"
      end

      def self.show_offset(s, options)
        if options.details
          puts "Offset: 0x%X 0%o %d" % [s.offset, s.offset, s.offset]
        else
          puts "0x%0X" % s.offset
        end
      end

      def self.show_size(s, options)
        if options.details
          puts "Size: 0x%X 0%o %d" % [s.size, s.size, s.size]
        else
          puts "0x%0X" % s.size
        end
      end

      def self.show_file(f, options)
        puts "#{options.details ? 'File: ' : ''}#{f.ident}"
      end

      def self.show_image(f, options)
        puts "#{options.details ? 'Image: ' : ''}#{f.image.ident}"
      end

      def self.show_arch_info(s, options)
        puts "#{options.details ? 'Arch Info: ' : ''}#{s.arch_info}"
      end

      def self.show_comment(s, options)
        txt = s.comment ? s.comment.text : ''
        puts "#{options.details ? 'Comment: ' : ''}#{txt}"
      end

      def self.show_raw_contents(s, options)
        $stdout.write s.contents
      end

      def self.show_hex_contents(s, options)
        puts "Contents:" if options.details
        idx = 0
        s.contents.bytes.each do |byte| 
          print "%08X:" % [idx] if (idx % 16 == 0)
          print " %02X" % byte
          idx += 1
          print "\n" if idx % 16 == 0
        end
        print "\n" if idx % 16 != 0
      end

      def self.list_sections(f, options)
        puts "Sections:" if options.details
        f.sections.each { |s| list_section(s, options) }
      end

      def self.list_section(obj, options)
        puts (options.details ? obj.inspect : obj.ident)
      end

    end

  end
end

