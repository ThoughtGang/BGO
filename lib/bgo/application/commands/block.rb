#!/usr/bin/env ruby
# :title: Bgo::Commands::Block
=begin rdoc
BGO command to list and examine Block objects in a Target or AddressContainer

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/block'

# TODO: finish arguments

module Bgo
  module Commands

=begin rdoc
A command to show Block objects in an AddressContainer.
=end
    class BlockCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      end_pipeline
      summary 'List or view BGO Block objects'
      usage "#{Commands.data_model_usage} [-abceil] [--full] OBJPATH [...]"
      help "List/View Target Blocks in a Project or from STDIN.
Category: porcelain

Options:
  -a, --addresses      Show address objects in Block
  -c, --comment        Show Block comment
  -i, --ident          Show Block ident
  -l, --list           List all Revisions for object (a Map or Section)
  -r, --recurse        Recurse into Blocks, listing all child Blocks
  -s, --size           Show size of Block
  -S, --symbols        Show symbols defined in Block Scope
  -v, --vma            Show load address of Block
  --full               Produce detailed output
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}
Note: The --stdout option has no effect in this command.
      
OBJPATH is the object path of a Target, an AddressContainer (e.g.  Map, Section)
object or a Block. 

Examples:
  # List all Block objects in Map 0x1000 in Process 999
  bgo block --full process/999/map/0x1000
  # List addresses in Block 1 of Map 0x500 in Process 1000
  bgo block -a process/1000/0x500map/revision/1
  # List changed bytes in Block 2 of Map 0x1000 in Process 999
  bgo block -b process/999/0x1000map/revision/2

See also: block-create, block-edit, block-delete
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          obj = state.item_at_obj_path ident
          if obj.respond_to? :address_containers
            list_ac_blocks(obj, options)
            next
          elsif obj.respond_to? :revisions
            list_blocks(obj, options)
            next
          elsif ! obj.kind_of? Bgo::ImageRevision
            $stderr.puts "Invalid object path: #{ident}"
            next
          end

          options.list_blocks ? list_block(obj, options) : \
                                show_block(obj, options)
        end

        true
      end

      def self.get_options(args)
        options = super

        options.idents = []

#        options.show_addresses = false
#        options.show_changed = false
        options.show_comment = false
        options.show_ident = false
        options.show_vma = false
        options.show_size = false
        options.list_blocks = false
        options.details = false

        opts = OptionParser.new do |opts|
#          opts.on( '-a', '--addresses' ) { options.show_addresses = true }
#          opts.on( '-b', '--changed-bytes' ) { options.show_changed = true }
          opts.on( '-c', '--comment' ) { options.show_comment = true }
          opts.on( '-i', '--ident' ) { options.show_ident = true }
          opts.on( '-l', '--list' ) { options.list_blocks = true }
          opts.on( '-s', '--size' ) { options.show_size = true }
          opts.on( '-v', '--vma' ) { options.show_vma = true }
          opts.on( '--full' ) { options.show_ident = options.show_comment = true
            options.show_vma = options.show_size = options.details = true }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1
        while args.length > 0
          options.idents << args.shift
        end

        select_show_full(options) if (! show_selected(options))

        return options
      end

      def self.show_selected(options)
        options.show_ident || options.show_vma || options.show_size ||
        options.show_comment
      end

      def self.select_show_selected(options)
        options.show_vma = options.show_size = options.show_ident = true
        options.show_comment = true
      end

      def self.show_block(blk, options)
        show_ident(blk, options) if options.show_ident
        show_vma(blk, options) if options.show_vma
        show_size(blk, options) if options.show_size
        show_comment(blk, options) if options.show_comment
#        show_changed_bytes(blk, options) if options.show_changed
#        show_addresses(blk, options) if options.show_addresses
      end

      def self.show_ident(blk, options)
        puts "#{options.details ? 'Object Path: ' : ''}#{blk.obj_path}"
      end

      def self.show_vma(blk, options)
        if options.details
          puts "VMA: 0x%X 0%o %d" % [blk.vma, blk.vma, blk.vma]
        else
          puts "0x%0X" % blk.vma
        end
      end

      def self.show_size(blk, options)
        if options.details
          puts "Size: 0x%X 0%o %d" % [blk.size, blk.size, blk.size]
        else
          puts "0x%0X" % blk.size
        end
      end

      def self.show_comment(blk, options)
        txt = blk.comment ? blk.comment.text : ''
        puts "#{options.details ? 'Comment: ' : ''}#{txt}"
      end

#      def self.show_changed_bytes(blk, options)
#        puts "Changed Bytes:" if options.details
#        blk.changed_bytes.sort { |a,b| a[0] <=> b[0] }.each do |k,v|
#          puts "%08X : %02X" % k, v
#        end
#      end

#      def self.show_addresses(blk, options)
#        puts "Addresses:" if options.details
#        blk.addresses.each do |addr|
#          puts "%08X : %s" % [addr.vma, addr.inspect]
#        end
#      end

      def self.list_ac_blocks(tgt, options)
        tgt.address_containers.each do |ac|
          puts "Container #{ac.class.name} #{ac.ident}:" # if options.details
          list_blocks(ac, options, "\t")
        end
      end

      def self.list_blocks(ac, options, indent='')
        ac.block.blocks.each { |blk| list_block(blk, options, indent) }
      end

      def self.list_block(obj, options, indent='')
        if obj.kind_of? Bgo::ImageRevision
          puts indent + (options.details ? obj.inspect : obj.ident.to_s)
        else
          puts "Not a BGO Revision: #{obj.class} #{obj.inspect}"
        end
      end

    end

  end
end

