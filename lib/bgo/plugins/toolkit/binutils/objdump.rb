#!/usr/bin/env ruby
# :title: Objdump Plugin
=begin rdoc
BGO Objdump loader plugin

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

A binary file loader plugin based on objdump (part of GNU binutils)

NOTE: This requires the GNU binutils objdump utility
=end

require 'bgo/application/plugin'

require 'bgo/file'
require 'bgo/file_format'
require 'bgo/map'
require 'bgo/section'

require 'bgo/disasm'
require 'bgo/address'
require 'bgo/instruction'

require 'bgo/plugins/shared/tempfile'

# TODO : config for binutils path

# NOTE: This will raise LoadError or Errno::ENOENT if objdump is missing
# TODO: change to only raise LoadError?
raise LoadError, 'objdump(1) not available' if `objdump -v`.chomp.empty?

require 'bgo/plugins/shared/isa' # Require every shared ISA plugin

# TODO: remove x86 assumptions
# TODO: add ident interface?
# TODO: expose objdump_target and objdump_disasm_target via API
# TODO: add support for more objdump operations (symtab, etc)
module Bgo
  module Plugins
    module Parser

      class Objdump
        extend Bgo::Plugin

        Bgo::FileFormat.supports 'ELF', 'AOUT', 'CORE'

        # ----------------------------------------------------------------------
        # DESCRIPTION

        name 'binutils-objdump'
        author 'dev@thoughtgang.org'
        version '1.0'
        description 'Load a file using objdump.'
        help 'Objdump Loader Plugin. Uses command-line utility objdump.
        Options..
        Etc...
        '

        # ----------------------------------------------------------------------
        # SPECIFICATIONS

        spec :parse_file, :parse, 25 do |file, hash|
          # TODO : actual confidence metric (e.g. can objdump handle tgt)
          25
        end

        spec :load_file, :load, 25 do |process, file, hash|
          # TODO : actual confidence metric (e.g. can objdump handle tgt)
          25
        end

        spec :disassemble, :disasm, 10 do |task, target|
          next 0 if (! task.linear?)
          # TODO : check if target architecture is supported.
          next 0 if (! (target.respond_to? :image))
          10
        end

        # ----------------------------------------------------------------------
        # API

        api_doc :parse, ['TargetFile', 'Hash'], 'Hash', \
                'Parse TargetFile using objdump(1)'
        def parse(file, opts={})
          # This modifies a Bgo::File, so buffers are not supported
          return if (! file.kind_of? Bgo::TargetFile)

          output = { :sections => [], :symbols => [] }

          # 1. Run objdump on file.image
          dump = objdump_target(file)
          output[:arch_info] = dump[:arch]

          # 2. Create a Section object for every section in file.
          #    NOTE: this does not handle missing section headers.
          dump[:section_headers].each do |sec|
            #cmt = "Created from section #{sec[:index]} by Objdump Loader plugin"

            flags = [ Map::FLAG_READ ]
            flags << Map::FLAG_WRITE if not \
                     sec[:flags].include? 'READONLY'
            flags << Map::FLAG_EXEC if sec[:flags].include? 'CODE'

            # Create Section object for this file section
            s = file.add_section( sec[:index].to_s, sec[:file_pos], sec[:size], 
                                  sec[:name], flags, dump[:arch] )
            output[:sections] << s
          end

          # TODO: symbols

          output
        end

        api_doc :load, ['Process', 'TargetFile', 'Hash'], 'Hash', \
                'Load TargetFile into Process using objdump(1)'
        def load(process, file, opts={})
          # This modifies a Bgo::Process via a Bgo::File
          return if not process.kind_of? Bgo::Process
          return if not file.kind_of? Bgo::TargetFile

          output = { :arch_info => nil, :maps => [], :images => [], 
                     :symbols => [] }
          img = file.image

          # 1. Run objdump on file.image
          dump = objdump_io(img.io)
          output[:arch_info] = dump[:arch]

          # 2. Create memory maps from file sections
          if (not dump[:program_headers].empty?)
            # by default, use program headers

            dump[:program_headers].each do |sec|
              # Skip program segments that are not loadable
              next if not sec[:type] == 'LOAD'

              #cmt = "Created from phdr '%d' in '%s' by Objdump Loader plugin." \
              #      % [sec[:index], file.name]

              flags = [ Map::FLAG_READ ]
              flags << Map::FLAG_WRITE if sec[:flags].include? 'w'
              flags << Map::FLAG_EXEC if sec[:flags].include? 'x'

              # Add a memory map for this program segment
              m = process.add_map_reloc( img, sec[:vaddr], sec[:offset], 
                                         sec[:file_size], flags, 
                                         dump[:arch_info] )
              # TODO: if m.tags[:needs_relocation]
              output[:maps] << m
            end

          else
            # otherwise, use section headers [note: this prob never happens]

            dump[:section_headers].each do |sec|
              # Skip file sections that are not allocated
              next if not sec[:flags].include? 'ALLOC'

              # Loadable sections can be read directly from the file
              # TODO: this can be replaced with a test that sets img for map
              if sec[:flags].include? 'LOAD'
                #cmt = "Created from section '%s' in '%s' by Objdump Loader plugin." % [sec[:name], file.name]

                flags = [ Map::FLAG_READ ]
                flags << Map::FLAG_WRITE if not \
                         sec[:flags].include? 'READONLY'
                flags << Map::FLAG_EXEC if sec[:flags].include? 'CODE'

                # Add a memory map for this file section
                m = process.add_map_reloc( img, sec[:vma], sec[:file_pos], 
                                           sec[:size], flags, dump[:arch_info] )
                # TODO: if m.tags[:needs_relocation]
                output[:maps] << m
              end
              # TODO: else handle .bss
              # non-loadable sections require a VirtualImage

            end

            # TODO: symbols
            # TODO: entry point?
          end

          output
        end

        api_doc :disasm, ['DisasmTask', 'Map|Section'], 'Hash', \
                'Perform disassembly task on Target using objdump(1)'
        def disasm(task, target)
          listing = objdump_disasm_target(target)

          # 2. invoke disassembly algorithm
          task.perform(target) do |image, offset, vma|
            addr = address_from_listing( vma, listing, target )
            target.add_address_object addr if addr
          end

          # 3. Return output of disassembly or true
          task.output ? task.output : {}
        end

        # ----------------------------------------------------------------------
        # Create array of Program Header Hashes from objdump output
        def program_headers( lines )
          headers = []
          index = 0
          lines.each_with_index do |line, idx| 
            next if idx % 2 == 1
            type, junk, offset, junk, vaddr, junk, paddr, junk, align = \
                  line.strip.split
            junk, filesz, junk, memsz, junk, flags = lines[idx+1].strip.split
            headers << { :index => index,
                         :type => type,
                         :vaddr => vaddr.hex,
                         :paddr => paddr.hex,
                         :offset => offset.hex,
                         :file_size => filesz.hex,
                         :mem_size => memsz.hex,
                         :flags => flags.split(''),
                         :align => 2**(align.split('**')[1].to_i) 
                       }
            index += 1
          end

          headers
        end

        # Create array of Section Header Hashes from objdump output
        def section_headers( lines )
          sections = []
          lines.each_with_index do |line, idx| 
            next if idx % 2 == 1
            flags = lines[idx+1].strip
            index, name, size, vma, lma, file_pos, align = line.strip.split

            sections << { :index => index.to_i,
                          :name => name,
                          :size => size.hex,
                          :vma => vma.hex,
                          :lma => lma.hex,
                          :file_pos => file_pos.hex,
                          :flags => flags.split(',').collect{ |f| f.strip },
                          :align => 2**(align.split('**')[1].to_i) 
                        }
          end
          sections
        end

        def objdump_output(path)
          lines = `objdump -x '#{path}'`.split("\n")

          # Determine location of important info in objdump output
          ph = sh = dyn = sym = arch = nil
          lines.each_with_index do |line, idx|
            ph = idx if line =~ /^Program Header:/ and not ph
            dyn = idx if line =~ /^Dynamic Section:/ and not dyn
            sh = idx if line =~ /^Sections:/ and not sh
            sym = idx if line =~ /^SYMBOL TABLE:/ and not sym
            arch = idx if line =~ /file format/ and not arch
          end

          raise 'Invalid objdump output' if (! (ph and dyn and sh and sym))

          { :arch => arch_from_file_format(lines[arch]),
            :program_headers => program_headers(lines[(ph+1)...(dyn-1)]),
            :section_headers => section_headers(lines[(sh+2)...sym])
          }
        end

        # determine architecture info from objdump output
        def arch_from_file_format(str)
          # NOTE: file format is handled by ident plugin
          fmt = str.split('file format')[1].strip
          arch_info = fmt.sub(/elf([0-9][0-9])?-/, '')
          # TODO: Do this properly!
          Bgo::ArchInfo.new(arch_info, fmt, Bgo::ArchInfo::ENDIAN_LITTLE)
        end

        # Run non-disasm objdump on the specified file
        def objdump_path(path)
          objdump_output(path)
        end

        # Create a temp file for buffer and run non-disasm objdump on it
        def objdump_buffer(buf)
          Bgo::tmpfile_for_buffer(buf, 'objdump-nondisasm') {|f|objdump_path(f.path)}
        end

        # Run non-disasm objdump on an IO object
        def objdump_io(io)
          ((io.respond_to? :path) && io.path) ? objdump_path(io.path) : 
                                                objdump_buffer(io.read)
        end

        # Run non-disasm objdump on a Map
        def objdump_target(tgt)
          if tgt.respond_to? :image
            io = tgt.image.io
            output = objdump_io(io)
            io.close
            return output
          end

          # else assume buffer
          objdump_buffer(tgt)
        end

        # Run disasm objdump on the specified file
        def objdump_disasm_path(path, start_addr, size)
          range = "--start-address=0x%X --stop-address=0x%X" % [start_addr, 
                                                             start_addr + size]
          #arch = 'unknown'
          insns = {}

          lines = `objdump -D #{range} '#{path}'`
          lines.split("\n").each do |line|
            insns[:arch] = arch_from_file_format(line) if line =~ /file format/
            next if line !~ /^\s*([[:xdigit:]]+):\s*(.*)$/
            insns[$1.hex] = $2
          end

          insns
        end

        # Create a temp file for buffer and run disasm objdump on it
        def objdump_disasm_buffer(buf, start_addr, size)
          Bgo::tmpfile_for_buffer(buf, 'objdump-disasm') do |f| 
            objdump_disasm_path( f.path, start_addr, size )
          end
        end

        # Run disasm objdump on an IO object
        def objdump_disasm_io(io, start_addr, size)
          ((io.respond_to? :path) && io.path) ? 
                                objdump_disasm_path(io.path, start_addr, size) :
                                objdump_disasm_buffer(io.read, start_addr, size)
        end

        # Run disasm objdump on a Map or Section
        def objdump_disasm_target(tgt)
          if (tgt.respond_to? :image) 
            img = tgt.image
            io = img.io
            # TODO: Verify this is True for a Map, Section
            output = objdump_disasm_io(io, tgt.start_addr, tgt.size)
            io.close
            return output
          end

          # else assume this is a buffer
          objdump_disasm_buffer(tgt, 0, tgt.size)
        end

        def address_from_listing(vma, listing, target)
          line = listing[vma]
          if (! line) or (line !~ /^(([[:xdigit:]]{2,2}\s)+)\s*(.*)$/ )
            return nil
          end

          hex_vma = $1
          asm = $3

          # TODO: extract into create_insn method
          # catch errors
          if asm =~ /<internal disassembler error>/
            # TODO : generate invalid instruction object
            #        using same size as insn?
            return nil
          end

          # Move objdump jump target names into comment
          asm.sub!(/^([^#]+)\s*(<[^>]+>)\s*$/, '\1 #\2')

          # Generate Instruction object
          insn_str, cmt = asm.split('#').collect { |x| x.strip }

          return nil if insn_str == '(bad)'

          # TODO: make this non-x86 specific
          arch = Plugins::Isa::X86_64::canon_arch(listing[:arch].arch.to_s)
          syntax = Plugins::Isa::X86::Syntax::ATT

          insn = Plugins::Isa::X86::Decoder.instruction(insn_str, arch, syntax)
#puts "BAD INSN #{hex_vma} #{asm}: #{line}" if not insn
# TODO : FIX rex.WR, rex.WRB, rex.WRX, fs, gs
#        ... i.e. prefix handling
          insn.comment = cmt if insn

          # Create Address object
          offset = target.vma_offset(vma)
          bytes = hex_vma.split(' ').collect { |x| x.hex }
          size = bytes.count
          addr = Address.new( target.image, offset, size, vma, insn )
          # TODO: address properties include metadata from libopcodes
          addr
        end


      end

    end
  end
end
