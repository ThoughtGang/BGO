#!/usr/bin/env ruby
# :title: Bgo::Commands::CreateAddress
=begin rdoc
BGO command to create a new Address in an AddressContainer.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/model_item'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/address'
require 'bgo/address_container'

module Bgo
  module Commands

=begin rdoc
A command to create an Address in an AddressContainer in a project or stream.
=end
    class CreateAddressCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Create a BGO Address in an AddressContainer'
      usage "#{Commands.data_model_usage} -a int -s int [-r int] [-c str] OBJPATH"
      help "Create an Address object for an AddressContainer in a Project or stream.
Category: plumbing

This creates a BGO Address object in an AddressContainer.

Options:
  -a, --addr num         Address: a VMA or offset (REQUIRED)
  -c, --comment string   Comment for Address object
  -r, --revision num     Revision containing Address (default: 0)
  -s, --size num         Size of Address (REQUIRED)
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

Examples:
  # Create an Address of 2048 bytes at offset 0x808000 in Process 999
  bgo process-address-create -a 0x808000 -s 2048 999
  # Create an Address of 4 bytes at offset 0x500 in Revision 2 of Process 1000
  bgo process-address-create -a 0x500 -s 4 -r 2 1000

See also: address, address-delete, address-edit, revision"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        raise "VMA argument required" if ! options.addr
        raise "Size argument required" if ! options.size

        obj = state.item_at_obj_path options.ident
        if obj.kind_of? Bgo::TargetObject
          target_create_address(obj, options)

        elsif obj.kind_of? Bgo::AddressContainer
          create_address(obj, options)

        else
          $stderr.puts "Not an AddressContainer : #{options.ident}"
          return false
        end

        state.save("Address added to #{options.ident} by cmd ADDRESS CREATE")
        true
      end

      def self.target_create_address(obj, options)
        ac = nil
        if obj.respond_to? :map_containing
          ac = obj.map_containing(options.addr)
        elsif obj.respond_to? :section_containing
          ac = obj.section_containing(options.addr)
        else
          $stderr.puts "#{obj.obj_path} contains no maps or sections"
        end
        
        if ac
=begin rdoc
        raise ("Size %d extends past map %X bounds" % [options.size, 
               m.start_addr]) if \
              (! m.contains?(options.addr + options.size - 1)) 
=end
          create_address(ac, options)
        else
          $stderr.puts "No AddressContainer found for VMA %X" % options.addr
        end
      end

      def self.create_address(obj, options)

        a = obj.add_address(options.addr, options.size, options.revision)
        a.comment = options.comment if a and options.comment
      end

      def self.get_options(args)
        options = super
        options.proc_ident = nil

        options.comment = nil
        options.revision = nil
        options.addr = 0
        options.size = nil

        opts = OptionParser.new do |opts|
          opts.on( '-c', '--comment string' ) { |str| options.comment = str }
          opts.on( '-r', '--revision id' ) {|n| options.revision = Integer(n)}
          opts.on( '-v', '--addr num' ) { |n| options.addr = Integer(n) }
          opts.on( '-s', '--size num' ) { |n| options.size = Integer(n) }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1
        options.ident = args.shift

        return options
      end

    end

  end
end

