#!/usr/bin/env ruby
# Utility to test manual objdump of project contents
# Copyright 2010 Thoughtgang <http://www.thoughtgang.org>

require 'bgo/git/project'
require 'bgo/git/file'
require 'bgo/disasm'
=begin
require 'bgo/address'
require 'bgo/instruction'

require 'bgo/plugins/shared/isa/x86'

# ----------------------------------------------------------------------
# Address
def define_address_for_insn( map, arch, str )
    if not str =~ /^\s*([[:xdigit:]]+):\s*(([[:xdigit:]]{2,2}\s)+)\s*(.*)$/
      return
    end
    vma = $1.hex
    offset = map.offset + (vma - map.start_addr)
    bytes = $2.split(' ').collect { |x| x.hex }
    size = bytes.count
    insn_str, cmt = $4.split('#').collect { |x| x.strip }

    #puts "#{arch} ADDR #{addr}|BYTES #{bytes.inspect}|INSN #{insn}"

    # create address
    addr = Bgo::Address.new( map.image, offset, size, vma )

    addr.comment = cmt if cmt && (not cmt.empty?)
    arch = Bgo::Plugin::Isa::X86_64::canon_arch(arch)
    syntax = Bgo::Plugin::Isa::X86::Syntax::ATT
    insn = Bgo::Plugin::Isa::X86::Decoder.instruction(insn_str, syntax, arch)

    addr.contents = insn
    puts "[#{addr.inspect}] :: #{insn.inspect}"

    # TODO:
    # map.add_address( vma, size, comment, index, force_instance )

end

# ----------------------------------------------------------------------
# Project
def arch_from_file_format(str)
  fmt = str.split('file format')[1].strip
  fmt.sub(/elf([0-9][0-9])?-/, '')
end

def disasm_map(proj, map)
  img = map.image

  # Refuse to handle virtual images (objdump won't know what to do with them)
  return if img.virtual?

  path = img.contents_path
  range = "--start-address=0x%X --stop-address=0x%X" % [map.start_addr, 
                                                      map.start_addr + map.size]
  #puts "objdump -D #{range} '#{path}'"
  lines = proj.repo.exec_in_git_dir { `objdump -D #{range} '#{path}'` }

  arch = 'unknown'
  lines.split("\n").each do |line|
    arch = arch_from_file_format(line) if line =~ /file format/

    define_address_for_insn( map, arch, line )
  end
end
=end

def disasm_process( proj, process )
  puts "DISASM PROCESS #{process.ident}"
  process.maps.each do |map|
    next if not (map.flags.include? Bgo::Map::FLAG_EXEC) 
    addrs = Bgo::Disassemble.linear(map)
    addrs.each do |vma,addr| 
      puts "[#{addr.inspect}] :: #{addr.contents.inspect}" if addr
    end

    #disasm_map(proj, map) if (map.flags.include? Bgo::Map::FLAG_EXEC) 
  end

end

def open_project(path)
  proj = Bgo::Git::Project.new(path)
  puts "NAME: " + proj.name
  puts "DESCR: " + proj.description
  puts "CREATED: " + proj.created.to_s
  puts "BGO VERSION: " + proj.bgo_version.to_s
  
  puts "IMAGES: " + proj.images.inspect
  puts "FILES: " + proj.files.inspect
  puts "PROCESSES:" + proj.processes.inspect

  proj
end

if __FILE__ == $0
  if ARGV.count == 0 
    puts "Usage: #{$0} path"
    exit 1
  end

  Bgo::PluginManager.load_all()

  proj = open_project(ARGV[0])

  proj.processes.each { |p| disasm_process(proj, p) }

end
