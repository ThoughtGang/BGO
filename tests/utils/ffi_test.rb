#!/usr/bin/env ruby

require 'ffi'
module LibElf
  extend FFI::Library
  EV_CURRENT = 1

  ffi_lib 'elf' # or path to library
  attach_function :elf_version, [ :int ], :int
end

LibElf.elf_version LibElf::EV_CURRENT
=begin
    Elf *elf_file;
    Elf_Kind  ek;
    int fd;

    fd = open(argv[1], O_RDONLY, 0);
    elf_file = elf_begin(fd, ELF_C_READ, NULL);
    ek = elf_kind(elf_file);

    elf_end(elf_file);
    close(fd);
=end
