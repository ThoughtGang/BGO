#!/usr/bin/env ruby
# :title: Bgo::Commands::File
=begin rdoc
BGO command to list and examine TargetFile objects

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/model_item'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/file'

module Bgo
  module Commands

=begin rdoc
A command to show project files
=end
    class FileCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      end_pipeline
      summary 'List or view BGO TargetFile objects'
      usage "#{Commands.data_model_usage} [-clirx] [--full] [IDENT] [...]"
      help "List/View TargetFile objects in a Project or from STDIN.
Category: porcelain

Options:
  -c, --comment        Show file comment
  -C, --children       Show child files
  -i, --ident          Show file ident
  -I, --image          Show image ident
  -l, --list           List all files
  -n, --name           Show filename
  -P, --path           Show full path to file
  -r, --raw            Output the raw binary contents of file
  -x, --hexdump        Output a hexdump of contents of file
  --full               Produce detailed output
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}
Note: The --stdout option has no effect in this command.
      
To list all TargetFiles in the Project, the command can be invoked with no
arguments.

To view a TargetFile, the IDENT argument must be provided. IDENT can be either
a File ident or the object path of a File object. The -x option can be used to 
display a hexdump of the contents of the file.

Examples:
  # List all TargetFile objects in the Project in ~/my_project.bgo
  bgo file -p ~/my_project.bgo
  # List files /tmp/a.bin /tmp/b.bin
  bgo file -l /tmp/a.bin /tmp/b.bin
  # List the contents of the File /tmp/a.out
  bgo file -x /tmp/a.out
  # Display only the comment of the File /tmp/a.out
  bgo file -c file/^tmp^a.out
  # Dump the binary contents of the File a.out
  bgo file -r a.out > file_data.bin
  # Display the contents of child File 'a.out' in parent file '/tmp/bin.tgz'
  bgo file --full file/^tmp^bin.tgz/file/a.out

See also: file-create, file-delete, file-edit, image
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        if options.idents.empty?
          puts "Files:" if options.details
          state.files.each { |f| list_file(f, options) }
          return true
        end

        options.idents.each do |ident|
          f = Commands.file_ident_or_path(state, ident)
          if f
            if options.list_files
              list_file(f, options)
              next
            end

            show_ident(f, options) if options.show_ident
            show_name(f, options) if options.show_name
            show_path(f, options) if options.show_path
            show_image(f, options) if options.show_image
            show_comment(f, options) if options.show_comment
            show_children(f, options) if options.show_children
            show_hex_contents(f, options) if options.show_hex
            show_raw_contents(f, options) if options.show_raw
          else
            $stderr.puts "File '#{ident}' not found in input"
          end
        end

        true
      end

      def self.get_options(args)
        options = super

        options.idents = []

        options.show_ident = false
        options.show_image = false
        options.show_path = false
        options.show_comment = false
        options.show_children = false
        options.show_hex = false
        options.show_raw = false
        options.details = false
        options.list_files = false

        opts = OptionParser.new do |opts|

          opts.on( '-i', '--ident' ) { options.show_ident = true }
          opts.on( '-I', '--image' ) { options.show_image = true }
          opts.on( '-P', '--path' ) { options.show_path = true }
          opts.on( '-n', '--name' ) { options.show_name = true }
          opts.on( '-C', '--children' ) { options.show_children = true }
          opts.on( '-r', '--raw' ) { options.show_raw = true }
          opts.on( '-x', '--hexdump' ) { options.show_hex = true }
          opts.on( '-c', '--comment' ) { options.show_comment = true }
          opts.on( '-l', '--list' ) { options.list_files = true }
          opts.on( '--full' ) { select_show_full options }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        while args.length > 0
          options.idents << args.shift
        end

        select_show_full(options) if not show_option_selected(options)

        return options
      end

      def self.show_option_selected(options)
        options.show_ident || options.show_comment || options.show_raw ||
        options.show_hex || options.show_image || options.show_name ||
        options.show_path || options.show_children
      end

      def self.select_show_full(options)
        options.show_ident = options.show_image = options.show_name = true
        options.show_path = options.show_comment = true
        options.show_children = true
      end

      def self.show_ident(f, options)
        puts "#{options.details ? 'Object Path: ' : ''}#{f.obj_path}"
      end

      def self.show_path(f, options)
        puts "#{options.details ? 'Path: ' : ''}#{f.full_path}"
      end

      def self.show_name(f, options)
        puts "#{options.details ? 'Name: ' : ''}#{f.name}"
      end

      def self.show_image(f, options)
        puts "#{options.details ? 'Image: ' : ''}#{f.image.ident}"
      end

      def self.show_comment(f, options)
        txt = f.comment ? f.comment.text : ''
        puts "#{options.details ? 'Comment: ' : ''}#{txt}"
      end

      def self.show_children(f, options)
        puts 'Children: ' if options.details
        f.child_files.each {|ident, c| puts options.details ? c.inspect : ident}
      end

      def self.show_raw_contents(f, options)
        $stdout.write f.contents
      end

      def self.show_hex_contents(f, options)
        puts "Contents:" if options.details
        idx = 0
        f.contents.bytes.each do |byte| 
          print "%08X:" % [idx] if (idx % 16 == 0)
          print " %02X" % byte
          idx += 1
          print "\n" if idx % 16 == 0
        end
        print "\n" if idx % 16 != 0
      end

      def self.list_file(obj, options)
        if obj.kind_of? Bgo::TargetFile
          puts (options.details ? obj.inspect : obj.ident)
        else
          puts "Not a BGO File: #{obj.class} #{obj.inspect}"
        end
      end

    end

  end
end

