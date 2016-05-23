#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Methods to fill Projects in Unit Tests

module Test
  module Project

    def self.fill_images(proj)
      binstr = "\x60\xFB\x41\xCC\xCD\x49\xFA\x61" * 1024
      img = proj.add_image(binstr)
      raise "Image created is not a Bgo::Image" if (! img.kind_of? Bgo::Image)
      raise "Image created is a virtual Bgo::Image" if (img.virtual?)
      raise "Image created is not correct size" if (binstr.length != img.size)
      img = proj.add_virtual_image("\xCC", 512)
      raise "Image created is not a Bgo::Image" if (! img.kind_of? Bgo::Image)
      raise "Image created is not a Bgo::VirtualImage" if \
        (! img.kind_of? Bgo::VirtualImage)
      raise "Image created is not a virtual Bgo::Image" if (! img.virtual?)
      raise "Image created is not correct size" if (512 != img.size)
    end

    def self.fill_files(proj)
      # TODO : child files
      img = proj.images.first
      f = proj.add_file_for_image('/tmp/a.out', img)  
      raise "File created is not a Bgo::File" if (! f.kind_of? Bgo::TargetFile)
      raise "File created is not correct size" if (f.size != img.size)
      data_size = (img.size / 4).to_i
      code_size = data_size * 3
      data_flags = Bgo::Section::DEFAULT_FLAGS
      code_flags = [Bgo::Section::FLAG_READ, Bgo::Section::FLAG_EXEC]
      ai = Bgo::ArchInfo.new 'x86', 'i386', Bgo::ArchInfo::ENDIAN_LITTLE
      cs = f.add_section(1, offset=0, code_size, 'text', code_flags, ai)
      ds = f.add_section(2, offset=code_size, data_size, 'data', data_flags, ai)
      fill_code_address_container(cs)
      fill_data_address_container(ds)
    end

    def self.fill_processes(proj)
      f = proj.files.first
      p = proj.add_process( './a.out', f.name )
      raise "Process created is not a Bgo::Process" if (! p.kind_of? Bgo::Process)
      img = proj.images.first
      code_vma = 0x80401000
      data_vma = 0x7E000000
      data_size = (img.size / 4).to_i
      code_size = data_size * 3
      code_flags = [Bgo::Map::FLAG_READ, Bgo::Map::FLAG_EXEC]
      data_flags = Bgo::Map::DEFAULT_FLAGS
      ai = Bgo::ArchInfo.new 'x86', 'i386', Bgo::ArchInfo::ENDIAN_LITTLE
      mc = p.add_map(img, code_vma, 0, code_size, code_flags, ai)
      md = p.add_map(img, data_vma, code_size, data_size, data_flags, ai)
      fill_code_address_container(mc)
      fill_data_address_container(md)
    end

    def self.fill_code_address_container(ac)
      #ac.image_offset
      base = ac.start_addr
      ac.add_address(base, 8)
      # TODO: add instruction
      #rev = ac.add_revision
      #add_address(vma, len, rev=nil)
    end

    def self.fill_data_address_container(ac)
      base = ac.start_addr
      ac.add_address(base, 128)
    end

  end
end
