#!/usr/bin/env ruby
# :title: Bgo::Commands::FileSectionEdit
=begin rdoc
BGO command to modify Section objects

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
A command to edit file sections
=end
    class FileSectionEditCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Edit BGO Section details'
      usage "#{Commands.data_model_usage} [-cfn str] [-os num] OBJPATH [...]"
      help "Modify Section objects in a Project or from STDIN.
Category: plumbing

Options:
  -c, --comment string  Set Section comment
  -f, --flags string    Set Section flags (e.g. 'rwx' or 'r-x')
  -n, --name string     Set Section name
  -o, --offset num      Set offset of Section in TargetFile
  -s, --size num        Set Section size
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

OBJPATH identifies the Map object to be modified.

Examples:
  # Set the comment for Section 1 in TargetFile /tmp/a.out
  bgo section-edit -c 'string data' /tmp/a.out 1

See also: section, section-create, section-delete
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          s = state.item_at_obj_path ident
          raise "Invalid object path: #{ident}" if ! s
          raise "Not a Section object: #{ident}" if ! s.kind_of? Bgo::Section

          s.comment = options.comment if options.comment
          s.flags = options.flags if options.flags 
          s.name = options.name if options.name 
          s.file_offset = options.offset if options.offset
          s.size = options.size if options.size

        end
        state.save("#{options.idents.join ', '} modified by cmd SECTION EDIT")

        true
      end

      def self.get_options(args)
        options = super

        options.idents = []
        options.comment = nil
        options.flags = nil
        options.name = nil
        options.offset = nil
        options.size = nil

        opts = OptionParser.new do |opts|

          opts.on( '-c', '--comment string' ) { |cmt| options.comment = cmt }
          opts.on( '-f', '--flags string' ) do |str|
            arr = str.split('')
            options.flags = Bgo::Section.validate_flags(arr) ? arr : nil
          end
          opts.on( '-n', '--name string' ) { |name| options.name = name }
          opts.on( '-o', '--offset num' ) { |n| options.offset = Integer(n) }
          opts.on( '-s', '--size num' ) { |n| options.size = Integer(n) }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1
        while args.length > 0
          options.idents << args.shift
        end

        return options
      end

    end

  end
end

