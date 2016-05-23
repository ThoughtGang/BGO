#!/usr/bin/env ruby
# :title: Bgo::Commands::CreateFileSection
=begin rdoc
BGO command to create a new Section in a TargetFile object

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
A command to create a Section for a TargetFile in a project or stream.
=end
    class CreateFileSectionCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Create a BGO Section in a TargetFile'
      usage "#{Commands.data_model_usage} [-i id] [-os int] [-nfc str] FILE"
      help "Create a Section object for a TargetFile in a Project or stream.
Category: plumbing

Options:
  -c, --comment string   Comment for Section object
  -f, --flags string     Sections flags in format 'rwx' (default 'rw-')
  -i, --ident string     ID of section (default TargetFile#sections.count)
  -n, --name string      Name of Section (default 'UNKNOWN')
  -o, --offset num       Offset of Section in TargetFile object (default 0)
  -s, --size num         Size of Section (default TargetFile.size)
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

The FILE argument identifies the File object, and can be a File ident or
an object path.

Examples:
  bgo section-create -i 0 -n code -f r-x /tmp/a.out
  bgo section-create -n .rodata -f r-- -o 100 -s 1024 /tmp/image.bin
  bgo section-create -i CTOR -n .ctor-noread -f '--x' -s 2048 /tmp/foo.o

See also: section, section-delete, section-edit"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        f = Commands.file_ident_or_path(state, options.file_ident)
        raise "File '#{options.file_ident}' not found" if ! f

        create_section(options, f)
        state.save("Section added by cmd FILE SECTION CREATE")

        true
      end

      def self.create_section(options, f)
        options.ident ||= f.sections.count
        options.size ||= f.size
        options.flags = gen_flags(options.flags)
        s = f.add_section(options.ident, options.offset, options.size, 
                          options.name, options.flags, nil)
        s.comment = options.comment if s and options.comment
      end

      def self.gen_flags(flags)
        arr = flags.split('')
        Bgo::Section.validate_flags(arr) ? arr : Bgo::Section::DEFAULT_FLAGS
      end

      def self.get_options(args)
        options = super
        options.file_ident = nil

        options.comment = nil
        options.flags = 'rw-'
        options.ident = nil
        options.name = 'UNKNOWN'
        options.offset = 0
        options.size = nil

        opts = OptionParser.new do |opts|
          opts.on( '-c', '--comment string' ) { |str| options.comment = str }
          opts.on( '-f', '--flags string' ) { |str| options.flags = str }
          opts.on( '-i', '--ident ident' ) { |id| options.ident = id }
          opts.on( '-n', '--name string' ) { |str| options.name = str }
          opts.on( '-o', '--offset num' ) { |n| options.offset = Integer(n) }
          opts.on( '-s', '--size num' ) { |n| options.size = Integer(n) }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1
        options.file_ident = args.shift

        return options
      end

    end

  end
end

