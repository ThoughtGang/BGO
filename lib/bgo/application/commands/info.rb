#!/usr/bin/env ruby
# :title: Bgo::Commands::Info
=begin rdoc
BGO command to list supported architectures and file formats

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/plugin_mgr'
require 'bgo/disasm'
require 'bgo/file_format'
require 'bgo/isa'
require 'bgo/plugins/shared/isa'  # load all ISA plugins

module Bgo
  module Commands

=begin rdoc
A command to list supported target architectures and object file formats.
=end
    class InfoCommand < Application::Command
# ----------------------------------------------------------------------
      disable_pipeline
      summary 'List supported architectures and file formats'
      usage '[pattern]'
      help 'Display a list of all supported architectures and object file formats. 
Category: porcelain

Options:
  -a, --arch      List supported target architectures
  -d, --disasm    List supported DisasmTask classes
  -f, --format    List supported object file formats

Examples:
  # List all supported architectures and file formats
  bgo info
  # List all supported architectures
  bgo info -a
  # List all supported file formats
  bgo info -f

See also: plugin-info, plugin-list
'
# ----------------------------------------------------------------------

      def self.invoke(args)
        options = get_options(args)
        list_arch if options.show_arch
        list_formats if options.show_fmt
        list_disasm if options.show_disasm
      end

      def self.get_options(args)
        options = super
        options.show_arch = false
        options.show_fmt  = false
        options.show_disasm  = false

        opts = OptionParser.new do |opts|
          opts.on( '-a', '--arch' ) { options.show_arch = true }
          opts.on( '-f', '--format' ) { options.show_fmt = true }
          opts.on( '-d', '--disasm' ) { options.show_disasm = true }
        end
        opts.parse!(args)

        if (! options.show_arch) && (! options.show_fmt)
          options.show_arch = options.show_fmt = options.show_disasm = true
        end

        return options
      end

      def self.list_arch
        puts 'Supported architectures:'
        puts Bgo::Isa.supported.join("\n")
      end

      def self.list_formats
        puts 'Supported formats:'
        puts Bgo::FileFormat.supported.map { |sym| sym.to_s }.join("\n")
      end

      def self.list_disasm
        puts 'Supported disasm tasks:'
        puts Bgo::DisasmTask.supported.map { |cls| cls.canon_name }.join("\n")
      end

    end

  end
end

