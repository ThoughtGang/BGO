#!/usr/bin/env ruby
# :title: Bgo::Commands::CreateFileInstruction
=begin rdoc
BGO command to create a new Instruction for a TargetFile Section Address.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/model_item'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/instruction'
require 'bgo/plugins/shared/isa'

module Bgo
  module Commands

=begin rdoc
A command to create an Instruction for an Address in a Section of a TargetFile 
in a project or stream.
=end
    class CreateFileInstructionCommand < Application::Command
# ----------------------------------------------------------------------
      summary 'Create a BGO Instruction for an Address in a TargetFile'
      usage "#{Commands.data_model_usage} [-r int] [-sac str] FILE OFFSET STR"
      help "Create an Instruction object for a TargetFile in a Project or stream.
Category: plumbing

This creates a BGO Instruction object for an Address in a TargetFile Section.
Note: If the Address object has not been defined, it will not be created.

Options:
  -a, --arch string      Target architecture (defaults to Section ArchInfo)
  -c, --comment string   Comment for Section object
  -r, --revision num     Map Revision containing Address
  -s, --syntax string    Assembly language syntax (e.g. Intel, AT&T), if needed
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

Examples:
  # Create an Instruction 'nop' at offset 0x100 in /tmp/a.out
  bgo file-insn-create /tmp/a.out 0x0100 nop
  bgo file-insn-create -a x86_64 -s att /tmp/a.out 0x0101 'movl %rsp, %rbp'
  bgo file-insn-create -s intel /tmp/a.out 0x0104 xor eax, ebx

See also: file-address, file-address-delete, file-address-edit"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        s = Commands.fetch_file_section_for_offset(state, options.file_ident,
                                                   options.offset)
        raise "No section for 0x%X in file %s" % 
              [options.offset, options.file_ident] if not s

        create_instruction(s, options)
        state.save("Insn added by cmd FILE INSN CREATE")

        true
      end

      def self.create_instruction(s, options)
        addr = s.address(options.offset, options.revision)
        raise "No such address 0x%X" % options.offset if ! addr
        raise "Address 0x%X already contains an Instruction object" % \
              options.offset if (addr.code?)

        options.arch ||= s.arch_info.arch.to_sym
        insn = Bgo::Plugins::Isa.decode(options.ascii, options.arch, 
                                        options.syntax)
        raise "Could not decode '%s' for %s %s" % [options.ascii, options.arch,
                                                   options.syntax] if ! insn
        addr.contents = insn
      end

      def self.get_options(args)
        options = super
        options.file_ident = nil
        options.offset = nil
        options.ascii = nil

        options.arch = nil
        options.comment = nil
        options.revision = nil
        options.syntax = nil

        opts = OptionParser.new do |opts|
          opts.on( '-a', '--arch string' ) { |str| options.arch = str.to_sym }
          opts.on( '-c', '--comment string' ) { |str| options.comment = str }
          opts.on( '-r', '--revision id' ) {|n| options.revision = Integer(n)}
          opts.on( '-s', '--syntax string' ) {|str| options.syntax = str.to_sym}

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 3

        options.file_ident = args.shift
        options.offset = Integer(args.shift)
        options.ascii = args.join(' ')
        args.clear

        return options
      end

    end

  end
end

