#!/usr/bin/env ruby
# :title: Bfd Plugin
=begin rdoc
BGO Bfd loader plugin

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

A binary file loader plugin based on libbfd (part of GNU binutils)
=end

require 'bgo/application/plugin'
require 'bgo/map'
require 'bgo/section'
require 'bgo/file_format'

require 'bgo/plugins/shared/tempfile'

require 'rubygems'
require 'BFD'

module Bgo
  module Plugins
    module Toolkit

      class Bfd
        extend Bgo::Plugin

        class InvalidBfdError < RuntimeError; end

        Bgo::FileFormat.supports 'ELF', 'AOUT', 'CORE'

        # ----------------------------------------------------------------------
        # DESCRIPTION 

        name 'binutils-BFD'
        author 'dev@thoughtgang.org'
        version '1.0'
        description 'Interface to the BFD library.'
        help 'Bfd Loader Plugin
Use the GNU binutils BFD library to identify, load, and parse files.
This requires the BFD gem from https://rubygems.org/gems/Opdis.'

        # ----------------------------------------------------------------------
        # SPECIFICATIONS

        spec :ident, :identify, 50 do |buf, path|
          ident = identify( buf )
          confidence = (ident.mime =~ /unknown/) ? 50 : 100
          confidence -= 50 if not ident.recognized?
          confidence
        end

        spec :parse_file, :parse, 50 do |file, hash|
          # TODO : actual confidence metric (e.g. can bfd handle tgt)
          50
        end

        spec :load_file, :load, 50 do |process, file, hash|
          # TODO : actual confidence metric (e.g. can bfd handle tgt)
          50
        end

        # ----------------------------------------------------------------------
        # API

        def created_by
          "Created by BFD Loader plugin."
        end

        def mime_from_bfd(bfd)
          return Bgo::Ident::MIME_COREDUMP if \
            bfd.format == ::Bfd::Target::FORMAT_CORE
          return Bgo::Ident::MIME_ARCHIVE if \
            bfd.format == ::Bfd::Target::FORMAT_ARCHIVE
          return Bgo::Ident::MIME_UNKNOWN if \
            bfd.format != ::Bfd::Target::FORMAT_OBJECT

          return Bgo::Ident::MIME_EXECUTABLE if bfd.is_executable?
          return Bgo::Ident::MIME_SHAREDLIB if bfd.is_shared_object?

          Bgo::Ident::MIME_OBJFILE
        end

        def arch_info_from_bfd(bfd)
          arch, mach = bfd.arch_info[:architecture].split(':')
          Bgo::ArchInfo.new(arch, mach, bfd.endian)
        end

        def ident_from_bfd(bfd)
          return Bgo::Ident.new( Bgo::Ident::CONTENTS_DATA, 
                                'Unrecognized object file',
                                'File type is not supported by BFD', 
                                'application/octet-stream', 
                                Bgo::Ident::FORMAT_UNKNOWN ) if not bfd.valid?

          contents = (bfd.format == ::Bfd::Target::FORMAT_CORE or 
                      bfd.format == ::Bfd::Target::FORMAT_OBJECT) ?
                                    Bgo::Ident::CONTENTS_CODE : 
                                    Bgo::Ident::CONTENTS_DATA
          summary = "#{bfd.type} #{bfd.format}"
          arch = bfd.arch_info[:architecture]
          full = "#{summary} #{bfd.endian} endian #{arch}"
          mime = mime_from_bfd(bfd)
          format = bfd.flavour.upcase

          Bgo::Ident.new( contents, summary, full, mime, format )
        end

        api_doc :identify, ['IO|buffer target'], 'Bgo::Ident', \
                'Use BFD to Identify Target'
        def identify(tgt, path='')
          ident = nil
          pos = tgt.pos if tgt.kind_of? IO

          begin
            bfd = (tgt.kind_of? String) ? ::Bfd::Target.from_buffer(tgt) : 
                                          ::Bfd::Target.new(tgt.path)
            ident = ident_from_bfd(bfd)
            bfd.close
          rescue InvalidBfdError
            ident = Bgo::Ident.unrecognized()
          end

          tgt.seek(pos) if tgt.kind_of? IO
          return ident
        end

        def bfd_on_io(io, &block)
          ((io.respond_to? :path) && io.path) ? block.call(io.path) :
              # Create a temp file for buffer and send to BFD
              Bgo::tmpfile_for_buffer(io.read, 'bfdtarget') { |f| 
                                                            block.call(f.path) }
        end

        api_doc :parse, ['TargetFile', 'Hash'], 'Hash', \
                'Use BFD to parse TargetFile'
        def parse(file, opts={})
          return if not file.kind_of? Bgo::TargetFile

          bfd_on_io( file.image.io ) { |path| parse_io_at_path(file, path) }
        end

        def parse_io_at_path(file, path)
          output = { :arch_info => nil, :sections => [], :symbols => [] }
          ::Bfd::Target.new(path) do |bfd|
            raise InvalidBfdError if not bfd.valid?

            ai = arch_info_from_bfd(bfd)
            output[:arch_info] = ai

            bfd.sections.each do |name, sec| 
              cmt = "From section %d (flags 0x%X). %s" %
                    [sec.index, sec.raw_flags, created_by]

              flags = [ Bgo::Section::FLAG_READ ]
              flags << Bgo::Section::FLAG_WRITE if not \
                       sec.flags.include? ::Bfd::Section::FLAG_RO
              flags << Bgo::Section::FLAG_EXEC if \
                       sec.flags.include? ::Bfd::Section::FLAG_CODE

              s = file.add_section( sec.index.to_s, sec.file_pos, sec.size, 
                                    sec.name, flags, ai )
              s.comment = cmt
              output[:sections] << s
            end

            # TODO: symbols, functions
          end

          output 
        end

        api_doc :load, ['Process', 'TargetFile', 'Hash'], 'Hash', \
                'Use BFD to load TargetFile into Process'
        def load(process, file, opts={})
          return if not process.kind_of? Bgo::Process
          return if not file.kind_of? Bgo::TargetFile

          bfd_on_io( file.image.io ) { |path| 
            load_io_at_path(process, file, path) 
          }
        end

        def load_io_at_path(process, file, path)
          output = { :arch_info => nil, :maps => [], :images => [], 
                     :symbols => [] }

          ::Bfd::Target.new(path) do |bfd|
            raise InvalidBfdError if not bfd.valid?

            ai  = arch_info_from_bfd(bfd)
            output[:arch_info] = ai
            
            bfd.sections.each do |name, sec| 

              next if not sec.flags.include? ::Bfd::Section::FLAG_ALLOC
              # TODO: is this necessary? Are 0-byte .bss sections created?
              next if sec.size == 0

              cmt = "From section '%s' in '%s' by %s. " %
                    [sec.name, file.name, created_by]

              img = file.image

              flags = [ Bgo::Map::FLAG_READ ]
              flags << Bgo::Map::FLAG_WRITE if not \
                       sec.flags.include? ::Bfd::Section::FLAG_RO
              flags << Bgo::Map::FLAG_EXEC if \
                       sec.flags.include? ::Bfd::Section::FLAG_CODE
              if (! (sec.flags.include? ::Bfd::Section::FLAG_LOAD))
                # Create virtual image for .bss and use it instead of img
                # FIXME: handle comment
                img = process.add_virtual_image("\000", sec.size)
                output[:images] << img
              end

              m = process.add_map_reloc( img, sec.vma, sec.file_pos, sec.size, 
                                        flags, ai )
              m.comment = cmt
              # TODO: if m.tags[:needs_relocation]
              output[:maps] << m
            end
            
            # TODO : symbols
          end

          output
        end

      end

    end
  end
end
