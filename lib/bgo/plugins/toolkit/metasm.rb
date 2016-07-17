#!/usr/bin/env ruby
# :title: Metasm Plugin
=begin rdoc
BGO Metasm toolkit plugin

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

NOTE: This requires the metasm framework from https://github.com/jjyg/metasm/
=end

# TODO: basic blocks: create in BGO
# TODO: tag entry points as such

require 'bgo/application/plugin'

require 'bgo/file'
require 'bgo/map'
require 'bgo/section'
require 'bgo/file_format'

require 'bgo/disasm'
require 'bgo/address'
require 'bgo/instruction'

require 'metasm'

require 'bgo/plugins/shared/isa' # Require every shared ISA plugin

module Bgo
  module Plugins
    module Toolkit

=begin rdoc
Plugin for using the Metasm framework inside BGO.

NOTE: currently this requires calling Metasm::AutoExe.decode_file in every
      specification. It should be possible to serialize the Metasm 'exe'
      object into the BGO ModelItem properties, and de-serialize it in
      the specification call if present.
      Might need metasm-ident properties for BGO ModelItems.
=end
      class Metasm
        extend Bgo::Plugin

        Bgo::FileFormat.supports 'ELF', 'COFF', 'Java Class', 'CORE', 'MachO'

        # ----------------------------------------------------------------------
        # DESCRIPTION

        name 'Metasm'
        author 'dev@thoughtgang.org'
        version '1.0'
        description 'Interface to the Metasm framework.'
        help 'Metasm Toolkit
Use the Metasm toolkit to ident, parse, load, disassemble, and analyze targets.
Metasm is available from https://github.com/jjyg/metasm and must be in the
Ruby module path.'

        # ----------------------------------------------------------------------
        # SPECIFICATIONS

        spec :ident, :identify, 20 do |buf, path|
          decode_target_headers(buf) ? 50 : 0
        end

        spec :parse_file, :parse, 50 do |file, hash|
          next 90 if file.property(:ident_plugin) == canon_name
          next 75 if (file.identified?) and \
                       (BGO_FORMAT.values.include file.ident_info.format)
          decode_target_headers(file.contents) ? 75 : 0
          0
        end

        spec :load_file, :load, 25 do |process, file, hash|
          next 90 if file.property(:ident_plugin) == canon_name
          next 75 if (file.identified?) and \
                       (BGO_FORMAT.values.include file.ident_info.format)
          decode_target_headers(file.contents) ? 75 : 0
          0
        end

        spec :disassemble, :disasm, 75 do |task, target|
          ai = target.arch_info
          # FIXME: determine if target architecture is supported
          75
        end

        spec :load_target, :load_target, 25 do |project, files, hash|
=begin
#FIXME : project not process
          ai = process.arch_info
          # FIXME: determine if target architecture is supported

          rv = 0
          files.each do |f|
            #return 90 if file.property(:ident_plugin) == canon_name
            # This sucks!! Better off using Process.arch_info
            rv = 100 if decode_target_headers(f.contents)
          end
=end
          30
        end

        # NOTE: only one analysis can be defined per-plugin. There will have to
        #       be multiple Metasm-based plugins defined in this file for
        #       additional analyses.
        spec :analysis, :analysis, 25 do |target, hash|
          25
        end

        # ----------------------------------------------------------------------
        # API

        api_doc :identify, ['String', 'String'], 'Ident', \
                'identify contents of a binary String using Metasm::AutoExe'
        def identify(buf, path='')
          obj = decode_target_headers(buf)
          return Bgo::Ident.unrecognized() if ! obj

          fmt = obj.shortname
          fmt = BGO_FORMAT[fmt] || fmt
          arch = arch_from_header(obj)
          mime = mime_from_header obj.header
          endian = endian_from_header(obj)
          summary = "%s %s %s-endian" % [fmt, arch, endian]
          full = description_from_header(fmt, obj.header)

          Bgo::Ident.new Bgo::Ident::CONTENTS_CODE, summary, full, mime, fmt
        end

        # =================================================================
        api_doc :parse, ['TargetFile|Packet', 'Hash'], 'Hash', \
                'Parse TargetFile using Metasm'
        def parse(tgt, opts={})
          return if not tgt.kind_of? Bgo::SectionedTargetObject

          obj = decode_target_file(tgt)
          return {} if ! obj

          output = { :sections => [], :symbols => [] }

          ai = decode_arch_info(obj)

          # 1) load sections
          decode_sections(tgt, obj, opts).each do |s|
            output[:sections] << add_section(tgt, s, ai) 
          end

          # 2) define symbols
          (obj.symbols || []).each do |s|
            next if ['NOTYPE', 'SECTION'].include? s.type
            output[:symbols] << define_symbol(tgt, obj, s) 
          end

          # 3) create references
          if obj.respond_to? :relocations     # MachO, for example, does not.
            (obj.relocations || []).each do |r|
              handle_reloc(tgt, obj, r)
            end
          end

          if obj.respond_to? :imports
            #$stderr.puts 'IMPORTS'
            #obj.imports.each { |x| $stderr.puts x.inspect }
          end
          #$stderr.puts obj.methods.sort

          # 4) parse debug info
          # FIXME: write this
          #$stderr.puts 'DEBUG'
          #(obj.debug || []).each { |x| $stderr.puts x.inspect }
          #$stderr.puts obj.methods.sort

          # 5) fill metadata (e.g. entrypoint)
          if obj.header.respond_to? :entry
            entry = obj.header.entry
            tgt.properties[:entry_point] = entry if entry
          end
          # TODO: More metadata

          output
        end

        # =================================================================
        api_doc :load, ['Process', 'TargetFile', 'Hash'], 'Hash', \
                'Load TargetFile into Process using Metasm'
        def load(process, file, opts={})
          return if not process.kind_of? Bgo::Process
          return if not file.kind_of? Bgo::SectionedTargetObject

          obj = decode_target_file(file)
          return {} if ! obj

          output = { :arch_info => nil, :maps => [], :symbols => [] }

          # TODO: set based on arch_info
          #ai = target.arch_info
          load_object(process, file, obj, opts, output)

          output
        end

        # =================================================================
        api_doc :disasm, ['DisasmTask', 'AddressContainer'], 'Hash', \
                'Perform disassembly task on Target using Metasm'
        def disasm(task, target)
          metasm_obj = {} # cache of metasm-disassembled targets

          ai = target.arch_info
          # TODO: set syntax based on arch_info
          syntax = syntax_for_arch(ai)

          begin
            # FIXME: metasm seems to be raising errors [BUG REPORT?]
            task.perform(target) do |image, offset, vma|
              metasm_obj[image.ident] ||= decode_target_image(image, ai)
              obj = metasm_obj[image.ident]
              if ! obj
                if $TG_PLUGIN_DEBUG
                  $TG_PLUGIN_DEBUG_STREAM.puts \
                    "Metasm: cannot process image #{image.ident}"
                end
                next
              end

              # vma_offset(vma)
              #obj.encoded.ptr = obj.disassembler.addr_to_fileoff(vma)
              obj.encoded.ptr = offset
              insn = obj.cpu.decode_instruction(obj.encoded, vma)
              addr = address_from_insn(vma, insn, ai.arch, syntax, obj, target)
              target.add_address_object(addr) if addr
            end
          rescue Exception => e
            if $TG_PLUGIN_DEBUG
              $TG_PLUGIN_DEBUG_STREAM.puts "Error in #{canon_name}.disasm:"
              $TG_PLUGIN_DEBUG_STREAM.puts e.message
              $TG_PLUGIN_DEBUG_STREAM.puts e.backtrace[0,4].join("\n")
            end
          end

          task.output || {}
        end

        # =================================================================
        api_doc :load_target, ['Project', 'String|Array'], 'Hash', \
                'Add files to Project and disassemble using Metasm'
        def load_target(project, files, opts={})
          return {} if (! project.kind_of? Bgo::Project)
          return {} if files.empty?

          bgo_files = []
          files.each do |f|
            bgo_files << project.add_file(f)
          end

          process = project.add_process(opts.cmd_line || bgo_files.first)

          output = { :arch_info => nil, :maps => [], :symbols => [] }

          # load all files into Process
          # TODO: ensure this is correct for metasm
          bgo_files.each do |f|
            m_obj = decode_target_file(f)
            next if ! m_obj

            load_object(process, f, m_obj, opts, output)

            disassemble_obj(process, f.image, m_obj, opts, output)
          end

          output
        end

=begin rdoc
=end
        # return the rebased VMA for a Metasm-generated VMA
        def rebased_vma(vma, maps)
          maps.each do |m|
            orig_vma = m.property :orig_vma
            if orig_vma && vma >= orig_vma && vma < orig_vma + m.size
              return (orig_vma - m.vma) + vma
            end
          end
          vma
        end

        # =================================================================
=begin NOT IMPLEMENTED
        api_doc :analysis, ['Target|Block'], 'AnalysisResults', \
                'Analyze target using Metasm'

        def analysis(target, opts={})
          # TODO: figure out what the primary Metasm analysis should be
          AnalysisResults.new
        end
=end

        # ----------------------------------------------------------------------
        # DECODE HEADERS

=begin rdoc
=end
        # convert Metasm architecture string to BGO architecture string
        BGO_ARCH = {
          'ia32' => 'x86',
          'ia32_be' => 'x86',
          'ia32_16' => 'x86',
          'x64' => 'x86-64',
          'x64_be' => 'x86-64'
        }

=begin rdoc
=end
        # convert Metasm exe_format string to BGO file format string
        BGO_FORMAT = {
          'aout' => 'aout',
          'bflt' => 'bFLT',         #uCLinux
          'coff' => 'COFF',
          'coffarchive' => 'COFF',
          'dex' => 'DEX',           # dalvik
          'dol' => 'Dol',
          'elf' => 'ELF',
          'fatelf' => 'ELF',
          #'gameboyrom' => 'GbROM',
          'javaclass' => 'Java',
          'macho' => 'MachO',
          'mz' => 'MZ',
          'nds' => 'NDS',           # Nintendo DS
          'pyc' => 'Pyc',
          #'shellcode' => 'shellcode',
          'swf' => 'SWF',
          #'universalbinary' => '',
          'xcoff' => 'COFF',
          'zip' => 'Zip'
        }

=begin rdoc
=end
        # convert BGO arch string to Metasm ISA class
        METASM_ISA_CLASS = {
          # FIXME: verify these, including ctor args
          'mips' => ::Metasm::MIPS.new,
          'arm' => ::Metasm::ARM.new,
          'android' => ::Metasm::Dalvik.new,
          'x86' => ::Metasm::Ia32.new,
          'x86-64' => ::Metasm::Ia32.new(64)
        }

=begin rdoc
=end
        def arch_from_header(hdr)
          return 'jvm' if hdr.kind_of? ::Metasm::JavaClass
          # TODO: handle ZIP as JAR?
          return 'unknown' if ! hdr.respond_to? :cpu
          arch = hdr.cpu.shortname
          BGO_ARCH[arch] || arch
        end

=begin rdoc
=end
        def endian_from_header(hdr)
          return 'big' if hdr.kind_of? ::Metasm::JavaClass
          # TODO: format-specific handling
          return 'unknown' if ! hdr.respond_to? :endianness
          hdr.endianness.to_s
        end

=begin rdoc
=end
        def mime_from_header(hdr)
          obj_type = nil
          obj_type = hdr.type if hdr.respond_to? :type
          obj_type ||= hdr.filetype if hdr.respond_to? :filetype
          obj_type ||= hdr.characteristics.join(' ') if \
                       hdr.respond_to? :characteristics

          return Bgo::Ident::MIME_OBJFILE if ! obj_type
          return Bgo::Ident::MIME_EXECUTABLE if obj_type =~ /EXEC/
          return Bgo::Ident::MIME_SHAREDLIB if obj_type =~ /DYN/
          return Bgo::Ident::MIME_SHAREDLIB if obj_type =~ /DLL/
          return Bgo::Ident::MIME_SHAREDLIB if obj_type =~ /DYLIB/
          return Bgo::Ident::MIME_COREDUMP if obj_type =~ /CORE/
          # UNUSED: Bgo::Ident::MIME_ARCHIVE

          Bgo::Ident::MIME_OBJFILE    # Note: this includes ELF REL
        end

=begin rdoc
=end
        # Metasm doesn't use a standard API for their header classes
        def description_from_header(fmt, hdr)
          keywords = [fmt]
          keywords << hdr.e_class if hdr.respond_to? :e_class
          keywords << hdr.data if hdr.respond_to? :data
          keywords << hdr.type if hdr.respond_to? :type
          keywords << hdr.filetype if hdr.respond_to? :filetype
          keywords << hdr.machine if hdr.respond_to? :machine
          keywords << hdr.cputype if hdr.respond_to? :cputype
          keywords << hdr.cpusubtype if hdr.respond_to? :cpusubtype
          keywords << hdr.flags.select { |f| f.kind_of? String }.join(',') if \
                      hdr.respond_to? :flags
          keywords << hdr.characteristics.join(' ') if \
                      hdr.respond_to? :characteristics
          keywords << hdr.abi if hdr.respond_to? :abi
          keywords.select { |s| s && ! s.empty? }.join ' '
        end

=begin rdoc
Build a BGO ArchInfo object for Metasm object file architecture.
=end
        def decode_arch_info(m_obj)
          arch = m_obj.cpu.shortname
          arch = BGO_ARCH[arch] || arch
          endian = m_obj.endianness.to_sym
          hdr = m_obj.header
          mach = (hdr.respond_to? :machine) ? hdr.machine : nil
          mach ||= (hdr.respond_to? :cpusubtype) ? hdr.cpusubtype : nil
          mach ||= (hdr.respond_to? :cputype) ? hdr.cputype : nil
          Bgo::ArchInfo.new arch, mach, endian
        end

=begin rdoc
=end
        def syntax_for_arch(ai)
          # FIXME: support non-intel syntax
          Plugins::Isa::X86::Syntax::INTEL
        end

        # ----------------------------------------------------------------------
        # LOAD/DECODE TARGET

=begin rdoc
Identify the file format of buf contents and return a Metasm object file
representation with the headers decoded.
=end
        def decode_target_headers(buf)
          begin
            buf && (! buf.empty?) ? ::Metasm::AutoExe.decode_header(buf) :
                                    ::Metasm::AutoExe.decode_file_header(path)
          rescue ::Metasm::AutoExe::UnknownSignature
            decode_java_target_headers(buf)
          end
        end

=begin rdoc
=end
        def decode_java_target_headers(buf)
          begin
            buf && (! buf.empty?) ? ::Metasm::JavaClass.decode(buf) :
                                    ::Metasm::JavaClass.decode_file(path)
          rescue ::Metasm::AutoExe::UnknownSignature
            nil
          end
        end

=begin rdoc
=end
        def decode_target_file(tgt)
          begin
            buf = tgt.contents
            obj = ::Metasm::AutoExe.decode_header(buf)
            decode_exe_format(obj)
          rescue ::Metasm::AutoExe::UnknownSignature
            # FIXME: better detection of JAVA files
            decode_java_target_file(tgt)
          end
        end

=begin rdoc
=end
        def decode_target_image(img, ai)
          buf = img.contents
          sc = METASM_ISA_CLASS[ai.arch.to_s] || ::Metasm::Ia32.new
          obj = ::Metasm::AutoExe.orshellcode(sc)
          if obj.kind_of? ::Metasm::ExeFormat
            decode_exe_format( obj.decode_header(buf) )
          else
            obj.decode(buf)
          end
        end

=begin rdoc
=end
        def decode_java_target_file(tgt)
          begin
            # FIXME: undefined method `decode_header' for Metasm::JavaClass
            #::Metasm::JavaClass.decode_header(tgt.contents)
            nil
          rescue ::Metasm::AutoExe::UnknownSignature
            nil
          end
        end
                
=begin rdoc
=end
        def decode_exe_format(obj)
            # Fix Metasm's broken object-init
            obj.symbols = [] if (obj.respond_to? :symbols=) and ! obj.symbols
            obj.relocations = [] if (obj.respond_to? :relocations=) and \
                                    ! obj.relocations

            obj.decode_sections if obj.respond_to? :decode_sections
            obj.decode_segments if obj.respond_to? :decode_segments
            obj
        end

=begin rdoc
=end
        def load_object(process, tgt, obj, opts, output={})
          img = tgt.image
          ai = decode_arch_info(obj)
          process.arch_info = ai if ! process.arch_info
          output[:arch_info] = ai

          # 1) load segments
          decode_segments(tgt, obj, opts).each do |s|
            output[:maps] << map_segment(process, img, obj, s, ai)
          end

          # 2) define symbols
          # FIXME: implement!

          # 3) create references
          # FIXME: implement!

          # 4) parse debug info
          # FIXME: implement!

          output
        end

        # ----------------------------------------------------------------------
        # SECTIONS

=begin rdoc
=end
        def decode_sections(tgt, obj, opts)
          sections = []
          if (obj.respond_to? :sections) && (! opts[:use_segments])
            (obj.sections || []).each do |s| 
              sec = decode_section(obj, s)
              next if sec[:empty]
              sections << sec
            end
          end

          # handle missing section headers
          if (sections.empty?) and (obj.respond_to? :segments)
            (obj.segments || []).each do |s| 
              seg = decode_segment(obj, s)
              next if seg[:file_sizes] == 0 && seg[:mem_size] == 0
              sections << seg
            end

            # if still empty, create one big segment
            sections << decode_single_section(tgt) if sections.empty?
          end

          # check for Mach-O: the program Segments contain Sections
          if (obj.respond_to? :segments) &&
             (obj.segments.first.respond_to? :sections)
            sections = decode_macho_sections(obj)
          end

          sections
        end

=begin rdoc
Decode Metasm ExeFormat::Section into a generic Section-or-Segment Hash.
=end
        def decode_section(m_obj, sec)
          flags = [ Map::FLAG_READ ]

          flags << Map::FLAG_WRITE if sec.flags.include? 'WRITE'
          flags << Map::FLAG_EXEC if (sec.flags.include? 'EXECINSTR') ||
                                     (sec.flags.include? 'CODE')
          # TODO: is_loadable, vma entries
          { :ident => sec.name, # TODO: other idents?
            :name => sec.name,
            :empty => (sec.size == 0 && ((! sec.name) || (sec.name.empty?))),
            :offset => sec.offset,
            :file_size => sec.size,
            :mem_size => sec.size,
            :flags => flags,
            :raw_flags => sec.flags,
            :raw_type => ((sec.respond_to? :type) ? sec.type : nil),
            :raw_info => ((sec.respond_to? :info) ? sec.info : nil)
          }
        end

=begin rdoc
=end
        def decode_single_section(tgt)
          { :ident => 'flatfile',
            :name => 'text',
            :is_loadable => true,
            :empty => false,
            :file_size => tgt.size,
            :mem_size => tgt.size,
            :offset => 0,
            :vma => 0,
            :flags => [Map::FLAG_READ, Map::FLAG_WRITE, Map::FLAG_EXEC]
          }
        end

=begin rdoc
Format-specific decoding for Mach-O binaries.
This file format consists of a small number of segments (e.g. __TEXT and __DATA)
which then contain the actual code and data sections.
This method will create sections from the list of segments in the Metasm object.
=end
        def decode_macho_sections(m_obj)
          sections = []
          (m_obj.segments || []).each do |seg|
            raw_flags = seg.initprot
            flags = [ Map::FLAG_READ ]
            flags << Map::FLAG_WRITE if (raw_flags.include? 'WRITE')
            flags << Map::FLAG_EXEC if (raw_flags.include? 'EXECUTE')

            (seg.sections || []).each do |sec|
              # FIXME: much of this is redundant with decode_sections
              info = (sec.attributes_sys || []) + (sec.attributes_usr || [])

              sections << { :ident => sec.segname + '.' + sec.name,
                            :name => sec.name,
                            :empty => (sec.size == 0),
                            :offset => sec.offset,
                            :vma => sec.addr,
                            :file_size => sec.size,
                            :mem_size => sec.size,
                            :flags => flags,
                            :raw_flags => raw_flags,
                            :raw_type => sec.type,
                            :raw_info => info }
            end
          end

          sections
        end

=begin rdoc
Decode a format-specific section definition from Metasm and add to a
BGO SectionedTarget object.
Note that the Metasm object file m_obj is passed in just-in-case.
=end
        def add_section(tgt, sec, ai)
          # Create Section object for this file section
          s = tgt.add_section(sec[:ident], sec[:offset], sec[:file_size], 
                              sec[:name], sec[:flags], ai)

          # store original metadata in properties
          s.properties[:header_flags] = sec[:raw_flags] if sec[:raw_flags]
          s.properties[:header_type] = sec[:raw_type] if sec[:raw_type]
          s.properties[:header_info] = sec[:raw_info] if sec[:raw_info]
          s
        end

        # ----------------------------------------------------------------------
        # SEGMENTS

=begin rdoc
=end
        def decode_segments(tgt, obj, opts)
          segments = []
          if (obj.respond_to? :segments) && ! (opts[:use_sections])
            (obj.segments || []).each { |s| 
              seg = decode_segment(obj, s)
              next if seg[:file_sizes] == 0 && seg[:mem_size] == 0
              next if ! seg[:is_loadable]
              segments << seg
            }
          end

          # Handle case where there are no segments defined
          if (segments.empty?) and (obj.respond_to? :sections)
            (obj.sections || []).each do |s|
              sec = decode_section(obj, s)
              next if sec[:empty]
              # TODO: remove non-loadable sections - sections must support this
              #next if ! sec[:is_loadable]
              segments << sec
            end

            # if still empty, create one big segment
            segments << decode_single_section(tgt) if segments.empty?
          end

          segments
        end

=begin rdoc
Decode Metasm ExeFormat::Segment into a generic Section-or-Segment Hash.
=end
        def decode_segment(m_obj, seg)
          raw_flags = [seg.flags].flatten
          raw_flags = seg.initprot if seg.respond_to? :initprot
          flags = [ Map::FLAG_READ ]
          flags << Map::FLAG_WRITE if (raw_flags.include? 'W') or
                                      (raw_flags.include? 'WRITE')
          flags << Map::FLAG_EXEC if (raw_flags.include? 'X') or
                                     (raw_flags.include? 'EXECUTE')

          name = (seg.respond_to? :name) ? seg.name : nil

          # ELF-specific
          vma = (seg.respond_to? :vaddr) ? seg.vaddr : nil
          offset = (seg.respond_to? :offset) ? seg.offset : nil
          file_sz = (seg.respond_to? :filesz) ? seg.filesz : nil
          mem_sz = (seg.respond_to? :memsz) ? seg.memsz : nil
          type = (seg.respond_to? :type) ? seg.type : nil
          # FIXME: generate name based on type etc
          # name ||= ...

          # MACHO-specific
          vma ||= (seg.respond_to? :virtaddr) ? seg.virtaddr : nil
          offset ||= (seg.respond_to? :fileoff) ? seg.fileoff : nil
          file_sz ||= (seg.respond_to? :filesize) ? seg.filesize : nil
          mem_sz ||= (seg.respond_to? :virtsize) ? seg.virtsize : nil
          type ||=  (seg.respond_to? :name) ? seg.name.upcase : nil

          ident = name || "0x%X" % vma
          type ||= ''

          is_loadable = (type.to_s == 'LOAD')
          if (seg.kind_of? ::Metasm::MachO::LoadCommand::SEGMENT)
            # MachO doesn't use anything sensible like FLAGS to determine this
            is_loadable = (name == '__TEXT' || name == '__DATA')
            # FIXME: Use MachO LoadCommand for this
          end

          { :ident => ident,
            :name => name || ident,
            :is_loadable => is_loadable,
            :empty => false,  # FIXME
            :file_size => file_sz,
            :mem_size => mem_sz,
            :offset => offset,
            :vma => vma,
            :flags => flags,
            :raw_type => type,
            :raw_flags => raw_flags
          }
        end

=begin rdoc
Map a segment Hash into Process memory.
=end
        def map_segment(p, img, m_obj, seg, ai) 
          # TODO: if filesz and memsz differ
          # TODO: .BSS
          m = p.add_map_reloc( img, seg[:vma], seg[:offset], seg[:file_size], 
                               seg[:flags], ai)
          # TODO: if m.tags[:needs_relocation]

          # store original metadata in properties
          m.properties[:header_flags] = seg[:raw_flags] if seg[:raw_flags]
          m.properties[:header_type] = seg[:raw_type] if seg[:raw_type]
          m.properties[:header_info] = seg[:raw_info] if seg[:raw_info]
          m
        end

        # ----------------------------------------------------------------------
        # DISASM

=begin rdoc
Generate an Address object for instruction.
=end
        def address_from_insn(vma, m_insn, arch, syntax, m_obj, tgt)
          return nil if ! m_insn

          txt = m_insn.instruction.to_s
# FIXME: 'sub rsp, 8' : 8 interpreted as IndirectAddress
          insn = Bgo::Plugins::Isa::X86::Decoder.instruction(txt, arch, syntax)
          # FIXME : analyze instruction directly, after decoding
          size = m_insn.bin_length
          addr = Address.new( tgt.image, tgt.vma_offset(vma), size, vma, insn )
          # comment seems to always be NULL
          #addr.set_comment([insn.comment].flatten.join(','), :disasm, 
          #                 self.name) if insn.comment
          #$stderr.puts insn.comment if insn.comment
          addr
        end

        #def vma_for_m_vma(m_obj, tgt, img, vma)
        #  offset = m_obj.addr_to_fileoff(vma)
        #  ac = tgt.address_container_for_image_offset(img, offset)
        #  ac.image_offset_vma(offset)
        #end

=begin rdoc
=end
        def ac_for_m_vma( tgt, img, m_obj, m_vma, cache )
          cache.keys.each do |range|
            return cache[range] if range.include? m_vma
          end

          offset = m_obj.addr_to_fileoff(m_vma)
          ac = tgt.address_container_for_image_offset(img, offset)
          cache[(m_vma..(m_vma+ac.size))] = ac
          ac
        end

=begin rdoc
=end
        def ac_vma_for_m_vma(ac, m_obj, m_vma )
          offset = m_obj.addr_to_fileoff(m_vma)
          ac.image_offset_vma(offset)
        end

=begin rdoc
Run Metasm disassembler on a Metasm ExeFormat object, and perform all
post-processing (e.g. creating blocks, strings, functions, references).

This takes a Bgo::Target, a Bgo::Image, the ExeFormat object, a Hash of options,
and a Hash for output as parameters.
=end

        def disassemble_obj(tgt, img, m_obj, opts={}, output={})
          # NOTE: output = { :arch_info => nil, :maps => [], :symbols => [] }
          ai = decode_arch_info(m_obj)
          # TODO: set based on arch_info
          syntax = Plugins::Isa::X86::Syntax::INTEL

          # 1. disassemble all entry points
          dis = (opts[:fast] || opts[:fastdeep] || opts[:fast_deep]) ?
                 m_obj.disassemble_fast_deep : m_obj.disassemble

          ac_cache = {}

          # 2. process Metsasm decoded instructions
          dis.decoded.each do |m_vma, insn|
            # metasm is not very reliable
            next if ! (insn.respond_to? :instruction)
            
            ac = ac_for_m_vma( tgt, img, m_obj, m_vma, ac_cache )
            vma = ac_vma_for_m_vma(ac, m_obj, m_vma )

            # TODO: where is ai defined?
            addr = address_from_insn(vma, insn, ai.arch, syntax, m_obj, ac)
            #$stderr.puts insn.comment.inspect
            label = dis.get_label_at(m_vma)
            if label
              # TODO: use as comment?
              # example: loc_400df2h
              #$stderr.puts label.inspect
            end

            if dis.comment[m_vma]
              # TODO: parse the comment as it contains useful info
              #       $stderr.puts dis.comment[m_vma] 
              # function binding: rsp -> rsp+8
              # function ends at 404cb8h
              addr.set_comment(dis.comment[m_vma], :function, self.name)
            end
            ac.add_address_object(addr) if addr && ac
          end

          # 3. Add blocks
          #   TODO: add list of basic blocks to AC as property?
          dis.each_instructionblock do |blk|
            # TODO: get block, order by size, then insert while ! in existing
            # InstructionBlock in ./metasm/disassemble.rb
            # edata : raw data
            # list : list of DecodedInstructions
            # from_normal : addr of insns giving control directly to block
            # to_normal  : addr of insns called/jumped to
            # from_subfuncret : addr of insn calling subfunc that rets to blk 
            # to_subfuncret : addr of insn executed after called subfunc rets
            # from_indirect, to_indirect : address of insns executed 
            #     indirectly through us (callback in a subfunction, SEH...)

            # TODO: fix
            ac = ac_for_m_vma( tgt, img, m_obj, blk.address, ac_cache )
            vma = ac_vma_for_m_vma(ac, m_obj, blk.address )
            #$stderr.puts "BLOCK 0x%X - 0x%X" % [blk.address, blk.address + blk.bin_length]
            # CAUSES CHILD BLOCK OVERLAP
            #ac.block.create_child(vma, blk.bin_length)
          end

          # 4. Add functions
          dis.function.each do |vma, f|
            # DecodedFunction in metasm/disassemble.rb
            # VMA : Integer OR Metasm::Expression 
            #       FUNC @ Expression["select"] RET nil
            # f.return_address
            # f.noreturn
            # f.localvars : Hash [StackOffset -> name]
            # localvars_xrefs : Hash [StackOffset -> insn addr]
            # dis.each_function_block(vma, false, true)
            # dis.callsites(f) -> [ VMA? ]
            # $stderr.puts "FUNC @ %s RET %s" % [vma.inspect, f.return_address.inspect]
            # create block for function

            # tgt.add_function
          end

          # 5. Add cross-references
          dis.xrefs.each do |vma, refs|
            # TODO: handle expressions, if necessary
            next if vma.kind_of? ::Metasm::Expression
            [refs].flatten.each do |ref| 
              next if ref.origin.kind_of? ::Metasm::Expression
              #handle_reference tgt, vma, ref, m_obj
              from_vma = ref.origin
              to_vma = vma
              handle_reference tgt, from_vma, to_vma, ref.type
            end
          end

          # 6. Add Strings
          # dis.strings_scan -> [ [VMA, Str] ]
          dis.strings_scan.each do |vma, str|
            #$stderr.puts vma.inspect + ': ' + str.inspect

            # tgt.add_string
            # 1. add address
          end
          
          # dis.function_graph -> Hash[ VMA -> Array[VMA|Expression|sym] ]
          # func => [list of direct subfuncs called]
          dis.function_graph.each do |vma, arr|
            #$stderr.puts "#{vma.inspect} : #{arr.inspect}"
          end

          dis
        end

        # ----------------------------------------------------------------------
        # SYMBOLS

=begin rdoc
Define a symbol in Target scope for symbol in Metasm object file.
=end
        def define_symbol(tgt, m_obj, m_sym)
          sym = nil

          # CodeSymbol DataSymbol ConstSymbol HeaderSymbol
          # ELF: 'NOTYPE' 'OBJECT' 'FUNC' 'SECTION' 'FILE' 'COMMON' 'TLS'
          #       bind: LOCAL GLOBAL WEAK
          #       name value size type bind other shndx 
          # COFF: 'NULL 'POINTER' 'FUNCTION' 'ARRAY'
          #       name value type_base type stoage
          # AOUT: UNDF ABS TEXT DATA BSS INDR SIZE COMM SETA SETT SETD SETB 
          #       SETV FN
          # MACHO: UNDF ABS INDR SECT TYPE

          case m_sym.type
          when 'FUNCTION', 'FUNC', 'TEXT'
            sym = Bgo::CodeSymbol.new(m_sym.name, m_sym.value)
          when 'OBJECT', 'DATA', 'BSS', 'POINTER'
            sym = Bgo::DataSymbol.new(m_sym.name, m_sym.value)
          # FIXME: Improve symbol support
          #when 'TYPE'
          #when 'ABS'
          #when 'INDR'
          else
            sym = Bgo::HeaderSymbol.new(m_sym.name, m_sym.value)
            #$stderr.puts "SYM [%s] %s = 0x%02X" % [m_sym.type, m_sym.name, m_sym.value]
          end

          tgt.scope.define(sym) if sym
        end

        # ----------------------------------------------------------------------
        # RELOCS

=begin rdoc
NOT IMPLEMENTED
=end
        def handle_reloc(tgt, m_obj, rel)
          # TODO: create Fixump reference?
          # ELF: offset, type, symbol, addend
          # COFF: va symidx type sym
          # type GLOB_DAT JMP_SLOT COPY RELATIVE TPOFF64 DTPMOD64 
          # ignore if ! sym?
          #$stderr.puts "0x%X %s (%s) %s" % [rel.offset, rel.type.to_s, (rel.symbol ? rel.symbol.name : 'UNKNOWN SYM'), rel.addend.to_s]
        end

        # ----------------------------------------------------------------------
        # REFERENCES

=begin rdoc
=end
        # FileRef LibRef FuncRef AddrRef (value)
        REF_ACCESS = { 'r' => ::Bgo::Reference::ACCESS_R,
                       'w' => ::Bgo::Reference::ACCESS_W,
                       'x' => ::Bgo::Reference::ACCESS_X }
=begin rdoc
=end
        def handle_reference( tgt, from_vma, to_vma, type )
          # TODO: support m_ref.len
          #from_ref = AddrRef.new(vma)
          #ref = Bgo::Reference.new ref_from, ref_to, REF_ACCESS[m_ref.type]

          ref = Bgo::Reference.addr_to_addr(from_vma, to_vma, REF_ACCESS[type])
          tgt.references << ref
        end

        # ----------------------------------------------------------------------
        # DISASMTASK

=begin rdoc
A DisasmTask which uses the Metasm plugin to generate VMAs of instruction
addresses.
Note that Metasm performs a full disassembly of the target, determining the
entrypoints itself. This DisasmTask is used primarily to generate a list of
VMAs for another disassembler, or to wrap Metasm with another disassembler
plugin. The Metasm target and disassembler objects are available while this
task is being performed.
=end
        class MetasmDisasmTask < Bgo::DisasmTask
=begin rdoc
Metasm ExeFormat (target) object.
This is only valid in the block passed to perform() and after perform() returns.
=end
          attr_reader :exe_format
=begin rdoc
Metasm Disassembler object.
This is only valid in the block passed to perform() and after perform() returns.
=end
          attr_reader :dis

=begin rdoc
An Array of VMAs to be passed to the Metasm disassembler.
=end
          attr_reader :entrypoints

          @canon_name = 'Metsasm (Backtracing Control Flow)'
          @sym = :metasm

          def initialize(entrypoints=[], output=nil, handler=nil, opts={})
            @entrypoints = entrypoints
            super (entrypoints.first || 0), output, handler, opts
          end

          def cflow?; true; end

          def emu?; true; end

=begin rdoc
=end
          def perform(target, &block)
            return if not target.respond_to? :contents
            @exe_format = decode_target_file(target, true)
            return if ! @exe_format 

            # TODO: entrypoints
            @dis = (@options[:fast] || @options[:fastdeep] || 
                    @options[:fast_deep]) ? @exe_format.disassemble_fast_deep : 
                                            @exe_format.disassemble

            # TODO: post-process OR flatten_graph or foreach vma,
            dis.decoded.each do |m_vma, insn|
              offset = @exe_format.addr_to_fileoff(m_vma)
              vma = m_vma
              if target.kind_of? Bgo::AddressContainer
                vma = target.image_offset_vma(offset)
              elsif target.kind_of? Bgo::Target
                # NOTE: If target supports :contents, it also supports :image
                ac = target.address_container_for_image_offset(target.image, 
                                                               offset)
                vma = ac.image_offset_vma(offset) if ac
              end

              # TODO: do something with instruction!
              # FIXME: write this
                
              super(target, vma, &block)
            end
            
          end

          #strings
          #blocks
          #functions
        end

      end

    end
  end
end

__END__
Metasm Notes

ExeFormat
  MZ: coff_offset com_header imports mz optheader resource
  ELF: get_default_entrypoints libraries: DT_NEEDED

Section
  COFF: virtsize virtaddr rawsize rawaddr relocaddr linenoaddr characteristics
        ? how to get fixups ?


DecodedInstruction
  block block_offset address instruction opcode bin_length comment

Disassembler
  obj.disassemble
  obj.disassemble_fast_deep
  dis = obj.disassembler
  dis.decoded Hash [vma => DecodedInstruction]
  dis.function Hash [vma => DecodedFunction]
  dis.xrefs : Hash [vma => [Xrefs]]
  dis.comment : Hash [vma [String]]
  dis.dump { |line| $stderr.puts line }
  block.edata.ptr = addr - block.address + block.edata_ptr
  dis.cpu.decode_instruction(block.edata, addr)
  # dis.entrypoints
  
  # dis.flatten_graph : "give something equivalent to the code 
  # accessible from the (list of) entrypoints given from the 
  # @decoded dasm graph
  #dis.entrypoints.each do |ep|
  #  $stderr.puts dis.flatten_graph(ep, true).inspect
  #end
  #[section__text:, xor ebp, ebp, mov r9, rdx, pop rsi, mov rdx, rsp, and rsp, -10h, push rax, push rsp, mov r8, sub_404c20h, mov rcx, sub_404c30h, mov rdi, loc_402be0h, call thunk___libc_start_main, thunk___libc_start_main:, jmp qword ptr [rip+20595ah], loc_402be0h:, push r15, push r14, push r13, mov r13d, 5, push r12, mov r12d, edi, push rbp, mov rbp, rsi, push rbx, xor ebx, ebx, sub rsp, 2188h, mov rax, fs:[28h], ...]

MACHO NOTES
  * cputype For example, in the above output, cputype is set to 18, which is CPU_TYPE_POWERPC, as defined in /usr/include/mach/machine.h. 
  * cpusubtype  attribute specifies the exact model of the CPU, and is generally set to CPU_SUBTYPE_POWERPC_ALL or CPU_SUBTYPE_I386_ALL.
  * filetype
    #define MH_OBJECT 0x1   /* relocatable object file */
    #define MH_EXECUTE  0x2   /* demand paged executable file */
    #define MH_FVMLIB 0x3   /* fixed VM shared library file */
    #define MH_CORE   0x4   /* core file */
    #define MH_PRELOAD  0x5   /* preloaded executable file */
    #define MH_DYLIB  0x6   /* dynamically bound shared library */
    #define MH_DYLINKER 0x7   /* dynamic link editor */
    #define MH_BUNDLE 0x8   /* dynamically bound bundle file */
    #define MH_DYLIB_STUB 0x9   /* shared library stub for static */
  * commands
    $stderr.puts '^^^^^^^ COMMANDS'
    $stderr.puts obj.commands.inspect if obj.respond_to? :commands
PE
  exe.optheader.entrypoint + exe.optheader.image_base
