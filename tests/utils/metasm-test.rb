#!/usr/bin/env ruby
# Test code to drive Metasm.
# Run this from bgo-rb directory (../..) with one argument: the path to a 
# binary file.
# Example:
#  ./metasm-test.rb tests/targets/linux-2.6.x-64.bin 

$: << File.join(File.dirname(__FILE__), 'dependencies', 'metasm')

require 'metasm'

fname = ARGV.shift

# unused -- metasm does not play well with binary strings as targets
#buf = File.binread(fname)

# load(VirtualFile.read(path), *a, &b)
# if str.kind_of?(EncodedData); e.encoded = str
#
# parse the file header
obj = nil
begin
  obj = Metasm::AutoExe.decode_file fname
  #obj = Metasm::AutoExe.decode_file_header(fname)
rescue Metasm::AutoExe::UnknownSignature
  $stderr.puts 'UNKNOWN SIG'
  exit -1
end

#puts obj.inspect
puts obj.class
puts obj.class.name
#:cursource :encoded :cpu 
#puts obj.methods.sort
puts obj.shortname.inspect
puts obj.filename.inspect
puts obj.endianness.inspect
puts obj.tag.inspect
#if obj.shortname == 'shellcode'
#dump_section_header
#each_section
#endianness
#filename
#header
#relocations
#sections
#segments
#shortname
#symbols
#tag
## WIN32:
# ! segments
# coff_offset
# com_header
# debug
# display
# imports
# mz
# optheader
puts obj.cpu.inspect
puts obj.cpu.shortname.inspect
#puts obj.cpu.methods.sort
# :endianness :size shortname
#obj.disassembler
puts obj.get_default_entrypoints.inspect
#obj.disassemble(entrypoints=[])
#obj.disassemble_fast_deep
#obj.header
puts obj.encoded.class
puts obj.encoded.ptr.inspect

# EncodedData methods: data reloc ptr virtsize rawsize
obj.get_default_entrypoints.each do |ep|
=begin
  obj.disassembler methods:
  di_at di_including disassemble_from fileoff_to_addr get_section_at
  get_label_at get_edata_at addr_to_fileoff normalize ...
=end
  #addr = normalize(addr)
  obj.encoded.ptr = obj.disassembler.addr_to_fileoff(ep)
  #puts "0x%08X" % obj.encoded.ptr

  insn = obj.cpu.decode_instruction(obj.encoded, ep)
  puts insn.inspect
end
obj.encoded.ptr = 0x00001A00
puts obj.cpu.decode_instruction(obj.encoded, 0x1000).to_s
#puts obj.disassembler.methods.sort

# manually specify file format
#exefmt = Metasm.const_get('ELF')
#puts exefmt.inspect
#exe = exefmt.decode_file(fname)
# puts exe.inspect


File.open(fname, 'rb') do |f|
  buf = f.read
  obj = Metasm::AutoExe.decode buf
  puts "Decoded File:"
  puts obj.class.name
  # load(VirtualFile.read(path), *a, &b) :
  #   if str.kind_of?(EncodedData); e.encoded = str
  #   else e.encoded << str

  #obj = Metasm::AutoExe.decode_file fname
  # load, decode
end

exit 1

# parse the file
obj = Metasm::AutoExe.orshellcode { Metasm::Ia32.new }.decode_file(fname)

obj = Metasm::AutoExe.decode_file(fname)
dasm = obj.disassembler
