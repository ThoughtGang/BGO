#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Methods to add targets and test their successful load/parse
# Unit test for BGO BFD Plugin

require 'test/unit'
require 'bgo/application/plugin_mgr'

require 'bgo/process'
require 'bgo/file'

module Test
  module Target
    TGT_DIR = File.join File.dirname(File.dirname(__FILE__)), 'targets'

    module LinuxExecutable64
      def self.init(proj)
        fname = TGT_DIR + File::SEPARATOR + 'linux-2.6.x-64.bin'
        # create a TargetFile object
        f = proj.add_file(fname)
        assert_not_nil(f)

        # create a Process object for TargetFile
        p = proj.add_process fname, fname
        assert_not_nil(p)
      end

      # Does no value checking. Runs ident and returns Bgo::Ident
      def self.ident(f, plugin) 
        assert(plugin.spec_supported? :ident)
        f.ident!(plugin)
        assert(f.identified?)
        assert_equal(Bgo::Ident, id.class)
        f.ident_info
      end

      def self.parse(f, plugin) 
        assert(plugin.spec_supported? :parse_file)
        f.parse!(plugin)
        assert_equal(27, f.sections.count)
        idents = (0..26).map { |x| x.to_s }
        names = [".interp", ".note.ABI-tag", ".note.gnu.build-id", ".hash", 
                 ".gnu.hash", ".dynsym", ".dynstr", ".gnu.version", 
                 ".gnu.version_r", ".rela.dyn", ".rela.plt", ".init", ".plt", 
                 ".text", ".fini", ".rodata", ".eh_frame_hdr", ".eh_frame", 
                 ".ctors", ".dtors", ".jcr", ".dynamic", ".got", ".got.plt", 
                 ".data", ".bss", ".gnu_debuglink"]
        offs = [568, 596, 628, 664, 1232, 1328, 3080, 3828, 3976, 4072, 4216, 
                5656, 5680, 6656, 19704, 19744, 23468, 23672, 28168, 28184, 
                28200, 28208, 28640, 28648, 29152, 29176, 29176]
        sizes = [28, 32, 36, 568, 92, 1752, 748, 146, 96, 144, 1440, 24, 976, 
                 13048, 14, 3722, 204, 956, 16, 16, 8, 432, 8, 504, 24, 524776, 
                 16]
        flags = [["r"], ["r"], ["r"], ["r"], ["r"], ["r"], ["r"], ["r"], ["r"], 
                 ["r"], ["r"], ["r", "x"], ["r", "x"], ["r", "x"], ["r", "x"], 
                 ["r"], ["r"], ["r"], ["r", "w"], ["r", "w"], ["r", "w"], 
                 ["r", "w"], ["r", "w"], ["r", "w"], ["r", "w"], ["r", "w"], 
                 ["r"]]

        arr = f.sections.to_a
        assert_equal( idents, arr.map { |s| s.ident } )
        assert_equal( names, arr.map { |s| s.name } )
        assert_equal( offs, arr.map { |s| s.offset } )
        assert_equal( sizes, arr.map { |s| s.size } )
        assert_equal( flags, arr.map { |s| s.flags } )
      end

      def self.load(p, f, plugin) 
        assert(plugin.spec_supported? :load_file)
        plugin.spec_invoke( :load_file, p, f, {} )
        assert_equal(26, p.maps.count)
        addrs = [4194872, 4194900, 4194932, 4194968, 4195536, 4195632, 4197384, 
                 4198132, 4198280, 4198376, 4198520, 4199960, 4199984, 4200960, 
                 4214008, 4214048, 4217772, 4217976, 6319624, 6319640, 6319656, 
                 6319664, 6320096, 6320104, 6320608, 6320640]
        offs = [568, 596, 628, 664, 1232, 1328, 3080, 3828, 3976, 4072, 4216, 
                5656, 5680, 6656, 19704, 19744, 23468, 23672, 28168, 28184, 
                28200, 28208, 28640, 28648, 29152, 29176]
        sizes = [28, 32, 36, 568, 92, 1752, 748, 146, 96, 144, 1440, 24, 976, 
                 13048, 14, 3722, 204, 956, 16, 16, 8, 432, 8, 504, 24, 495600]
        flags = [["r"], ["r"], ["r"], ["r"], ["r"], ["r"], ["r"], ["r"], ["r"], 
                 ["r"], ["r"], ["r", "x"], ["r", "x"], ["r", "x"], ["r", "x"], 
                 ["r"], ["r"], ["r"], ["r", "w"], ["r", "w"], ["r", "w"], 
                 ["r", "w"], ["r", "w"], ["r", "w"], ["r", "w"], ["r", "w"]]

        arr = p.maps.to_a
        assert_equal( addrs, arr.map { |s| s.start_addr } )
        assert_equal( offs, arr.map { |s| s.image_offset } )
        assert_equal( sizes, arr.map { |s| s.size } )
        assert_equal( flags, arr.map { |s| s.flags } )
        assert_equal( ai.inspect, arr[0].arch_info.inspect )
      end

    end
  end
end
