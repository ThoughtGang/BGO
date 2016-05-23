#!/usr/bin/env ruby
# :title: Bgo::Commands::CreateProcessMap
=begin rdoc
BGO command to create a new Section in a TargetFile object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/model_item'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/map'

module Bgo
  module Commands

=begin rdoc
A command to create a Map for a Process in a project or stream.
=end
    class CreateProcessMapCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Create a BGO Map in a Process'
      usage "#{Commands.data_model_usage} [-i id] [-vos num] [-fc str] PROC"
      help "Create a Map object for an Image in a Project or stream.
Category: plumbing

This creates a BGO Map object in a Process.

Options:
  -c, --comment string   Comment for Map object
  -f, --flags string     Map flags in format 'rwx' (default 'rw-')
  -i, --image ident      Ident of Image object (default: VirtualImage)
  -o, --offset num       Offset of Map in Image object (default 0)
  -s, --size num         Size of Map (default Image.size)
  -v, --vma addr         Load address of Map (default 0)
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

The PROC argument identifies the Process object, and can be a numeric ID or
an object path. The -i option is used to specify the ident of an Image object 
to be mapped into the Process. If -i is not specified, a (zero-filled) 
VirtualImage object is created of -s bytes. This means that one of -i or -s 
MUST be provided.

Examples:
  # Map a 100-byte VirtualImage to VMA 0 in process 999
  bgo map-create -s 100 999
  # Map Image a01baa79948cdcc0d928ab67eff004a3ece60b5c to VMA 8040100
  bgo map-create -i a01baa79948cdcc0d928ab67eff004a3ece60b5c \
      -v 0x8041000 -f 'r-x' 999

See also: map, map-delete, map-edit"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        p = Commands.process_ident_or_path(state, options.proc_ident)
        raise "Process not found" if ! p
        img = options.image_ident ? state.image(options.image_ident) : 
                                    add_virtual_image(state, options)

        create_map(options, p, img)
        state.save("MAP added by cmd PROCESS MAP CREATE")

        true
      end

      def self.get_options(args)
        options = super

        options.proc_ident = nil
        options.image_ident = nil

        options.vma = 0
        options.offset = 0
        options.size = nil
        options.flags = 'rw-'
        options.comment = nil

        opts = OptionParser.new do |opts|
          opts.on( '-c', '--comment string' ) { |str| options.comment = str }
          opts.on( '-f', '--flags string' ) { |str| options.flags = str }
          opts.on( '-i', '--image ident' ) { |id| options.image_ident = id }
          opts.on( '-o', '--offset num' ) { |n| options.offset = Integer(n) }
          opts.on( '-s', '--size num' ) { |n| options.size = Integer(n) }
          opts.on( '-v', '--vma addr' ) { |addr| options.vma = Integer(addr) }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1

        options.proc_ident = args.shift

        return options
      end

      def self.add_virtual_image(state, options)
        raise "Size argument required to create VirtualImage" if ! options.size
        cmt = "Autocreated by PROCESS-MAP-CREATE command"
        fill = "\x00"
        img = state.add_virtual_image fill, options.size
        img.comment = cmt if img
        img
      end

      def self.create_map(options, p, img)
        options.size ||= img.size
        flags = gen_flags(options.flags)
        m = p.add_map(img, options.vma, options.offset, options.size, flags,
                      nil)
        m.comment = options.comment if m and options.comment
      end

      def self.gen_flags(flags)
        arr = flags.split('')
        Bgo::Map.validate_flags(arr) ? arr : Bgo::Map::DEFAULT_FLAGS
      end

    end

  end
end

