#!/usr/bin/env ruby
# :title: Bgo::Commands::DecodeInstruction
=begin rdoc
BGO command to decode an instruction to STDOUT.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/plugin_mgr'

require 'bgo/instruction'

module Bgo
  module Commands

=begin rdoc
A command to decode one or more assembly language instructions
=end
    class DecodeInstructionCommand < Application::Command
# ----------------------------------------------------------------------
      disable_pipeline
      summary 'Decode one or more assembly language instructions'
      usage "[-sau str] [PATH]"
      help "Generate BGO Instruction objects for assembly language statements.
Category: porcelain

Options:
  -a, --arch string         Target architecture
  -s, --syntax string       Assembly language syntax (e.g. Intel, AT&T)
  -u, --use-plugin string   Specify plugin to use for :decode_insn spec

The assembly-language input is either read from a file (the PATH argument) or 
from STDIN. The output is a JSON-encoded Array of Instruction objects.

Examples:
  echo 'nop' | bgo decode-insn -a x86
  echo 'xor eax, eax' | bgo decode-insn
  echo 'add eax, ecx
  push eax
  push ebx
  push 0
  call 0x010000
  mov [ebp+4], eax' | bgo decode-insn

See also: insn-create, info, plugin-info"
# ----------------------------------------------------------------------

      def self.invoke(args)
        options = get_options(args)
        plugin = find_decoder(options)
        if ! plugin
          if options.plugin
            $stderr.puts "Could not find plugin '#{options.plugin}'"
          else
            $stderr.puts "No suitable plugin for decoding #{options.inspect}"
          end
          return false
        end

        arch = options.arch
        syn  = options.syntax
        insns = []
        options.asm.each do |line|
          insns << plugin.spec_invoke(:decode_insn, line, arch, syn)
        end

        $stdout.puts insns.map { |i| i.to_hash }.to_json

        true
      end

      def self.find_decoder(options)
        options.plugin ?
            Bgo::Application::PluginManager.find(options.plugin) :
            Bgo::Application::PluginManager.fittest_providing(:decode_insn, 
                                                             options.asm.first,
                                                             options.arch,
                                                             options.syntax)
      end

      def self.get_options(args)
        options = super
        options.asm = []

        options.arch = ''
        options.plugin = nil
        options.syntax = ''

        # TODO: option to not use ARGF. -p ? -l?
        opts = OptionParser.new do |opts|
          opts.on( '-a', '--arch string' ) { |str| options.arch = str }
          opts.on( '-u', '--use-plugin string' ) { |str| options.plugin = str }
          opts.on( '-s', '--syntax string' ) {|str| options.syntax = str }
        end

        opts.parse!(args)

        options.asm = ARGF.readlines.map! { |line| line.chomp }

        return options
      end

    end

  end
end

