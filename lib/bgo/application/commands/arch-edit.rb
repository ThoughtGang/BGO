#!/usr/bin/env ruby
# :title: Bgo::Commands::ArchInfoEdit
=begin rdoc
BGO command to set ArchInfo for Bgo model objects

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/process'

module Bgo
  module Commands

=begin rdoc
A command to edit architecture info
=end
    class ArchInfoEditCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Edit ArchInfo details for a Bgo object'
      usage "#{Commands.data_model_usage} -a str -[b|l] [-m str] OBJPATH [...]"
      help "Set ArchInfo for a Bgo model object in a Project or from STDIN.
Category: plumbing

Options:
  -a, --arch string     Set architecture string (Required)
  -b, --big-endian      Set endian to BIG
  -l, --little-endian   Set endian to LITTLE
  -m, --mach string     Set machine string
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

The OBJPATH argument identifies the Bgo data model item to apply the ArchInfo
changes to.

Note that one of -b or -l is required.

Examples:
  # Set the ArchInfo to x86_64 little-endian for process 999
  bgo process-arch-edit -a x86_64 -l process/999
  # Set the ArchInfo to x86 i386 little-endian process 1000
  bgo process-arch-edit -a x86 -m i386 -l process/1000

See also: file, map, process, section.
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        raise "Incomplete ArchInfo data" if ! (options.arch || options.endian)

        ai = ArchInfo.new(options.arch, options.mach, options.endian)

        options.idents.each do |ident|
          obj = state.item_at_obj_path ident
          if (! obj.respond_to? :arch_info=)
            $stderr.puts "Invalid object path: #{ident}"
            next
          end

          obj.arch_info = ai
        end

        state.save("#{options.idents.join ','}' modified by cmd ARCH EDIT")

        true
      end

      def self.get_options(args)
        options = super

        options.idents = []
        options.arch = nil
        options.mach = Bgo::ArchInfo::UNKNOWN
        options.endian = nil

        opts = OptionParser.new do |opts|

          opts.on( '-a', '--arch string' ) { |str| options.arch = str }
          opts.on( '-b', '--big-endian' ) {
                  options.endian = Bgo::ArchInfo::ENDIAN_BIG }
          opts.on( '-l', '--little-endian' ) { 
                  options.endian = Bgo::ArchInfo::ENDIAN_LITTLE }
          opts.on( '-m', '--mach string' ) { |str| options.mach = str }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1

        while args.count > 0
          options.idents << args.shift
        end

        return options
      end

    end

  end
end

