#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO binutils-based Plugins

require 'test/unit'
require 'bgo/application/plugin_mgr'

require 'bgo/file'
require 'bgo/image'
require 'bgo/process'
require 'bgo/disasm'

$objdump_present = false
$bfd_present = false
$opcodes_present = false

class TC_PluginLoader < Test::Unit::TestCase
  TGT_DIR = File.dirname(File.dirname(__FILE__)) + File::SEPARATOR + 'targets'

  def test_1_requirements
    begin
      if not `objdump -v`.chomp.empty?
        $objdump_present = true
      end
    rescue Errno::ENOENT
      $objdump_present = false
      $stderr.puts "Objdump not installed. Not running objdump tests."
    end

    begin
      require 'BFD'
      $bfd_present = true
    rescue LoadError
      $bfd_present = false
      $stderr.puts "Could not find BFD gem: not running BFD tests."
    end

    begin
      require 'Opcodes'
      $opcodes_present = true
    rescue LoadError
      $stderr.puts "Could not find Opcodes gem: not running opcodes tests."
    end

    return if (! $objdump_present) && (! $bfd_present) && (! $opcodes_present)

    Bgo::Application::PluginManager.init
    Bgo::Application::PluginManager.startup Bgo::Application.lightweight
  end

  # ----------------------------------------------------------------------
  def test_2_objdump
    return if ! $objdump_present

    proj, f, p = load_target_file 'linux-2.6.x-64.bin'

    plugin = Bgo::Application::PluginManager::find('binutils-objdump')
    assert_not_nil(plugin)
    assert(plugin.spec_supported? :parse_file)
    assert(plugin.spec_supported? :load_file)
    assert(plugin.spec_supported? :disassemble)

    # Parse TargetFile contents
    plugin.spec_invoke( :parse_file, f, {} )
    assert_equal(27, f.sections.count)
    # TODO: better unit tests for parse results

    # Load TargetFile into Process
    plugin.spec_invoke( :load_file, p, f, {} )
    assert_equal(2, p.maps.count)
    # TODO: better unit tests for load results

    p.maps.each do |m|
      next if (! m.flags.include? Bgo::Map::FLAG_EXEC)
      # Create a disassembly task
      # args: start_addr=m.vma, range=nil, output={}, handler=nil, opts={}
      task = Bgo::LinearDisasmTask.new(m.start_addr, nil, {}) 

      # addrs=
      plugin.spec_invoke( :disassemble, task, m ) if m.executable?

      #addrs.keys.sort.each do |vma|
      #  $stderr.puts addrs[vma].ascii
      #end
      # TODO: actual unit tests
    end

  end

  # ----------------------------------------------------------------------
  def test_3_bfd_opcodes
    return if not $bfd_present

    proj, f, p = load_target_file 'linux-2.6.x-64.bin'

    plugin = Bgo::Application::PluginManager::find('binutils-BFD')
    assert_not_nil(plugin)

    # ===============================================================
    # Identify TargetFile
    assert(plugin.spec_supported? :ident)
    assert(plugin.spec_supported? :parse_file)
    assert(plugin.spec_supported? :load_file)

    f.ident!(plugin)
    assert(f.identified?)
    id = f.ident_info
    assert_equal(Bgo::Ident, id.class)
    assert(id.recognized?)
    assert_equal('ELF', id.format)
    assert_equal('elf64-x86-64 object', id.summary)
    assert_equal('elf64-x86-64 object little endian i386:x86-64', id.full)
    assert_equal('application/x-executable', id.mime)
    assert_equal(Bgo::Ident::CONTENTS_CODE, id.contents)

    ai = Bgo::ArchInfo.new "i386", "x86-64", Bgo::ArchInfo::ENDIAN_LITTLE

    # ===============================================================
    # Parse TargetFile contents
    f.parse!(plugin)
    assert_equal(27, f.sections.count)
    idents = (0..26).map { |x| x.to_s }
    names = [".interp", ".note.ABI-tag", ".note.gnu.build-id", ".hash", 
             ".gnu.hash", ".dynsym", ".dynstr", ".gnu.version", 
             ".gnu.version_r", ".rela.dyn", ".rela.plt", ".init", ".plt", 
             ".text", ".fini", ".rodata", ".eh_frame_hdr", ".eh_frame", 
             ".ctors", ".dtors", ".jcr", ".dynamic", ".got", ".got.plt", 
             ".data", ".bss", ".gnu_debuglink"]
    offs = [568, 596, 628, 664, 1232, 1328, 3080, 3828, 3976, 4072, 4216, 5656,
            5680, 6656, 19704, 19744, 23468, 23672, 28168, 28184, 28200, 28208,
            28640, 28648, 29152, 29176, 29176]
    sizes = [28, 32, 36, 568, 92, 1752, 748, 146, 96, 144, 1440, 24, 976, 
             13048, 14, 3722, 204, 956, 16, 16, 8, 432, 8, 504, 24, 524776, 16]
    flags = [["r"], ["r"], ["r"], ["r"], ["r"], ["r"], ["r"], ["r"], ["r"], 
             ["r"], ["r"], ["r", "x"], ["r", "x"], ["r", "x"], ["r", "x"], 
             ["r"], ["r"], ["r"], ["r", "w"], ["r", "w"], ["r", "w"], 
             ["r", "w"], ["r", "w"], ["r", "w"], ["r", "w"], ["r", "w"], ["r"]]
    arr = f.sections.to_a
    assert_equal( idents, arr.map { |s| s.ident } )
    assert_equal( names, arr.map { |s| s.name } )
    assert_equal( offs, arr.map { |s| s.offset } )
    assert_equal( sizes, arr.map { |s| s.size } )
    assert_equal( flags, arr.map { |s| s.flags } )
    assert_equal( ai.inspect, arr[0].arch_info.inspect )

    # ===============================================================
    # Load TargetFile into Process
    plugin.spec_invoke( :load_file, p, f, {} )
    assert_equal(26, p.maps.count)
    addrs = [4194872, 4194900, 4194932, 4194968, 4195536, 4195632, 4197384, 
             4198132, 4198280, 4198376, 4198520, 4199960, 4199984, 4200960, 
             4214008, 4214048, 4217772, 4217976, 6319624, 6319640, 6319656, 
             6319664, 6320096, 6320104, 6320608, 6320640]
    offs = [568, 596, 628, 664, 1232, 1328, 3080, 3828, 3976, 4072, 4216, 5656,
            5680, 6656, 19704, 19744, 23468, 23672, 28168, 28184, 28200, 28208,
            28640, 28648, 29152, 29176]
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

    # ===============================================================
    # finished loading with BFD, now try disasm with opcodes
    return if not $opcodes_present

    plugin = Bgo::Application::PluginManager::find('binutils-opcodes')
    assert_not_nil(plugin)

    p.maps.each do |m|
      next if (! m.flags.include? Bgo::Map::FLAG_EXEC)
      # Create a disassembly task
      #start_addr, range, output, handler, opts
      task = Bgo::LinearDisasmTask.new(m.start_addr, nil, {}) 

      addrs = plugin.spec_invoke( :disassemble, task, m ) if m.executable?

      #addrs.keys.sort.each do |vma|
      #  $stderr.puts addrs[vma].ascii
      #end
    end
  end

  def test_9999_shutdown
    #Bgo::Application::PluginManager.shutdown Bgo::Application.lightweight
  end

  def load_target_file(target_file)
    proj = Bgo::Project.new
    fname = File.join TGT_DIR, target_file
    # create TargetFile
    f = proj.add_file(fname)
    assert_not_nil(f)
    # create a Process object for TargetFile
    p = proj.add_process fname, fname
    assert_not_nil(p)
    [proj, f, p]
  end

end
