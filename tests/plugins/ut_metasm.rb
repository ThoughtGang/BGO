#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Metasm Plugin
# Example:
#   RUBYLIB="$RUBYLIB:dependencies/metasm" tests/plugins/ut_metasm.rb 


require 'test/unit'
require 'bgo/application/plugin_mgr'

require 'bgo/project'
require 'bgo/process'
require 'bgo/file'

$metasm_present = false

class TC_PluginToolkitMetasm < Test::Unit::TestCase
  TGT_DIR = File.dirname(File.dirname(__FILE__)) + File::SEPARATOR + 'targets'

  def test_1_requirements
    begin
      require 'metasm'
      $metasm_present = true
    rescue LoadError
      $stderr.puts "Could not find 'metasm' in module path: not running tests."
    end
    return if not $metasm_present

    Bgo::Application::PluginManager.init
    Bgo::Application::PluginManager.startup Bgo::Application.lightweight

    plugin = Bgo::Application::PluginManager::find('Metasm')
    assert_not_nil(plugin)
    assert(plugin.spec_supported? :ident)
    assert(plugin.spec_supported? :parse_file)
    assert(plugin.spec_supported? :load_file)
  end

  def test_2_linux
    return if not $metasm_present

    plugin = Bgo::Application::PluginManager::find('Metasm')
    # proj = Bgo::Project.new
    # fname = path_to_target 'linux-2.6.x-64.bin' 
    #plugin.spec_invoke( :load_target, proj, fname, {} )
    #return
    
    proj, f, p = load_target_file 'linux-2.6.x-64.bin' 

    # Identify TargetFile
    f.ident!(plugin)
    assert(f.identified?)
    id = f.ident_info
    assert_equal(Bgo::Ident, id.class)
    assert(id.recognized?)
    assert_equal('ELF', id.format)
    assert_equal('ELF x86-64 little-endian', id.summary)
    assert_equal('ELF 64 LSB EXEC X86_64 SYSV', id.full)
    assert_equal('application/x-executable', id.mime)
    assert_equal(Bgo::Ident::CONTENTS_CODE, id.contents)

    # Parse TargetFile contents
    f.parse!(plugin)
    assert_equal(28, f.sections.count)
    sec_names = [".bss", ".ctors", ".data", ".dtors", ".dynamic", ".dynstr", 
                 ".dynsym", ".eh_frame", ".eh_frame_hdr", ".fini", ".gnu.hash",
                 ".gnu.version", ".gnu.version_r", ".gnu_debuglink", ".got", 
                 ".got.plt", ".hash", ".init", ".interp", ".jcr", 
                 ".note.ABI-tag", ".note.gnu.build-id", ".plt", ".rela.dyn", 
                 ".rela.plt", ".rodata", ".shstrtab", ".text"]
    assert_equal(sec_names, f.sections.map { |s| s.name }.sort)

    # Load TargetFile into Process
    p.load!(f, plugin, {})
    assert_equal(2, p.maps.count)
    maps = ["24628@0x400000", "1008@0x606E08"]
    assert_equal(maps, p.maps.map {|m| "%d@0x%X" % [m.size, m.start_addr]} )
    # Disassemble all executable maps
    p.maps.each do |m|
      next if (! m.flags.include? Bgo::Map::FLAG_EXEC)
      # create disassembly task
      task = Bgo::LinearDisasmTask.new(m.start_addr, nil, {})
      # perform disassembly
      addrs = plugin.spec_invoke( :disassemble, task, m ) if m.executable?
      # show all addresses...
    end

    # same, with shared library
    proj, f, p = load_target_file 'linux-2.6.x-64.so' 
    f.ident!(plugin)
    assert(f.identified?)
    id = f.ident_info
    assert_equal('ELF', id.format)
    assert_equal('ELF x86-64 little-endian', id.summary)
    assert_equal('ELF 64 LSB DYN X86_64 SYSV', id.full)
    assert_equal('application/x-sharedlib', id.mime)
    assert_equal(Bgo::Ident::CONTENTS_CODE, id.contents)
    f.parse!(plugin)
    sec_names = [".bss", ".ctors", ".data", ".data.rel.ro", ".dtors", 
                 ".dynamic", ".dynstr", ".dynsym", ".eh_frame", ".eh_frame_hdr",
                 ".fini", ".gcc_except_table", ".gnu.hash", ".gnu.version", 
                 ".gnu.version_d", ".gnu.version_r", 
                 ".gnu.warning.pthread_attr_getstackaddr", 
                 ".gnu.warning.pthread_attr_setstackaddr", ".gnu_debuglink", 
                 ".got", ".got.plt", ".hash", ".init", ".interp", ".jcr", 
                 ".note.ABI-tag", ".note.gnu.build-id", ".plt", ".rela.dyn", 
                 ".rela.plt", ".rodata", ".shstrtab", ".strtab", ".symtab", 
                 ".text", "__libc_freeres_fn"]
    assert_equal(36, f.sections.count)
    assert_equal(sec_names, f.sections.map { |s| s.name }.sort)
    plugin.spec_invoke( :load_file, p, f, {} )
    assert_equal(2, p.maps.count)
    maps = ["96028@0x0", "1720@0x217BB8"]
    assert_equal(maps, p.maps.map {|m| "%d@0x%X" % [m.size, m.start_addr]} )

    # same, with LLVM-generated executable
    proj, f, p = load_target_file 'i686_ELF/llvmbin' 
    f.ident!(plugin)
    assert(f.identified?)
    id = f.ident_info
    assert_equal('ELF', id.format)
    assert_equal('ELF x86 little-endian', id.summary)
    assert_equal('ELF 32 LSB EXEC 386 SYSV', id.full)
    assert_equal('application/x-executable', id.mime)
    assert_equal(Bgo::Ident::CONTENTS_CODE, id.contents)
    f.parse!(plugin)
    assert_equal(35, f.sections.count)
    sec_names = [".bss", ".comment", ".ctors", ".data", ".debug_abbrev", 
                 ".debug_frame", ".debug_info", ".debug_line", 
                 ".debug_pubnames", ".debug_pubtypes", ".dtors", ".dynamic", 
                 ".dynstr", ".dynsym", ".eh_frame", ".eh_frame_hdr", ".fini", 
                 ".gnu.hash", ".gnu.version", ".gnu.version_r", ".got", 
                 ".got.plt", ".init", ".interp", ".jcr", ".note.ABI-tag", 
                 ".note.gnu.build-id", ".plt", ".rel.dyn", ".rel.plt", 
                 ".rodata", ".shstrtab", ".strtab", ".symtab", ".text"]
    assert_equal(sec_names, f.sections.map { |s| s.name }.sort)
    plugin.spec_invoke( :load_file, p, f, {} )
    assert_equal(2, p.maps.count)
    maps = ["1536@0x8048000", "256@0x8049F14"]
    assert_equal(maps, p.maps.map {|m| "%d@0x%X" % [m.size, m.start_addr]} )

    # Test load_target spec
    proj, f, p = load_target_file 'linux-2.6.x-64.bin' 
    plugin.spec_invoke( :load_target, p, [f], {} )
    # TODO: do something with result! e.g. check maps
  end

  # ----------------------------------------------------------------------
  def test_3_win32
    return if not $metasm_present
    plugin = Bgo::Application::PluginManager::find('Metasm')
    proj, f, p = load_target_file 'DOTNET/hello.net.exe' 
    f.ident!(plugin)
    assert(f.identified?)
    id = f.ident_info
    assert_equal('COFF', id.format)
    assert_equal('COFF x86 little-endian', id.summary)
    assert_equal('COFF I386 EXECUTABLE_IMAGE x32BIT_MACHINE', id.full)
    assert_equal('application/x-executable', id.mime)
    assert_equal(Bgo::Ident::CONTENTS_CODE, id.contents)
    #$stderr.puts 'WIN32 EXE'
    #crashes with:
    # NoMethodError: undefined method `name' for nil:NilClass
    # dependencies/metasm/metasm/exe_format/coff_decode.rb:556:in `decode'

    #f.parse!(plugin)
    #$stderr.puts f.sections.map { |s| s.name }.sort.inspect
    #$stderr.puts f.sections.count
    #crashes with:
    # NoMethodError: undefined method `name' for nil:NilClass
    # dependencies/metasm/metasm/exe_format/coff_decode.rb:553:in `decode_sections'
    #plugin.spec_invoke( :load_file, p, f, {} )
    #$stderr.puts p.maps.count
    #$stderr.puts p.maps.map {|m| "%d@0x%X" % [m.size, m.start_addr]}.inspect
    #assert_equal(2, p.maps.count)
    #maps = 
    #assert_equal(maps, p.maps.map {|m| "%d@0x%X" % [m.size, m.start_addr]} )
  end

  # ----------------------------------------------------------------------
  def test_4_arm
    return if not $metasm_present
    plugin = Bgo::Application::PluginManager::find('Metasm')
    proj, f, p = load_target_file 'ARM_ELF/armbin' 
    f.ident!(plugin)
    assert(f.identified?)
    id = f.ident_info
    assert_equal('ELF', id.format)
    assert_equal('ELF arm little-endian', id.summary)
    assert_equal('ELF 32 LSB EXEC ARM SYSV', id.full)
    assert_equal('application/x-executable', id.mime)
    assert_equal(Bgo::Ident::CONTENTS_CODE, id.contents)
    f.parse!(plugin)
    assert_equal(36, f.sections.count)
    sec_names = [".ARM.attributes", ".ARM.exidx", ".bss", ".comment", ".data", 
                 ".debug_abbrev", ".debug_aranges", ".debug_frame", 
                 ".debug_info", ".debug_line", ".debug_loc", ".debug_str", 
                 ".dynamic", ".dynstr", ".dynsym", ".eh_frame", ".fini", 
                 ".fini_array", ".gnu.hash", ".gnu.version", ".gnu.version_r", 
                 ".got", ".init", ".init_array", ".interp", ".jcr", 
                 ".note.ABI-tag", ".note.gnu.build-id", ".plt", ".rel.dyn", 
                 ".rel.plt", ".rodata", ".shstrtab", ".strtab", ".symtab", 
                 ".text"]
    assert_equal(sec_names, f.sections.map { |s| s.name }.sort)
    plugin.spec_invoke( :load_file, p, f, {} )
    assert_equal(2, p.maps.count)
    maps = ["1260@0x8000", "296@0x10F04"] 
    assert_equal(maps, p.maps.map {|m| "%d@0x%X" % [m.size, m.start_addr]} )
  end

  # ----------------------------------------------------------------------
  def test_5_java
    return if not $metasm_present
    plugin = Bgo::Application::PluginManager::find('Metasm')
    proj, f, p = load_target_file 'Java/HelloWorld.class' 
    f.ident!(plugin)
    assert(f.identified?)
    id = f.ident_info
    #$stderr.puts id.inspect
    #f.parse!(plugin)
    # FIXME: This creates zero sections
    #$stderr.puts f.sections.map { |s| s.name }.sort.inspect
    #$stderr.puts f.sections.count
    # FIXME: This creates zero maps
    #plugin.spec_invoke( :load_file, p, f, {} )
    #$stderr.puts p.maps.count
    #$stderr.puts p.maps.map {|m| "%d@0x%X" % [m.size, m.start_addr]}.inspect
    #assert_equal(2, p.maps.count)

    #JAR SUPPORT BROKEN IN METASM
    #proj, f, p = load_target_file 'HelloWorld.jar' 
    #f.ident!(plugin)
    #assert(f.identified?)
    #id = f.ident_info
    #$stderr.puts "**#{f.name}**"
    #$stderr.puts id.inspect
  end
=begin Java support not functional in Metasm
=end

  # ----------------------------------------------------------------------
  def test_6_ios
    return if not $metasm_present
    plugin = Bgo::Application::PluginManager::find('Metasm')
    proj, f, p = load_target_file 'ARM_Mach-O/iOS.bin' 
    f.ident!(plugin)
    assert(f.identified?)
    id = f.ident_info
    assert_equal('MachO', id.format)
    assert_equal('MachO arm little-endian', id.summary)
    assert_equal('MachO EXECUTE ARM ARMV6 NOUNDEFS,DYLDLINK,TWOLEVEL', id.full)
    assert_equal('application/x-executable', id.mime)
    assert_equal(Bgo::Ident::CONTENTS_CODE, id.contents)
    f.parse!(plugin)
    assert_equal(17, f.sections.count)
    sec_names = [ "__bss", "__cfstring", "__const", "__cstring", "__data", 
                  "__lazy_symbol", "__nl_symbol_ptr", "__objc_classlist", 
                  "__objc_classrefs", "__objc_const", "__objc_data", 
                  "__objc_imageinfo", "__objc_selrefs", "__program_vars", 
                  "__stub_helper", "__symbolstub1", "__text" ]
    assert_equal(sec_names, f.sections.map { |s| s.name }.sort)
    plugin.spec_invoke( :load_file, p, f, {} )
    assert_equal(2, p.maps.count)
    maps = ["40960@0x1000", "4096@0xB000"]
    assert_equal(maps, p.maps.map {|m| "%d@0x%X" % [m.size, m.start_addr]} )
  end

  # ----------------------------------------------------------------------
  # NOT IMPLEMENTED
=begin
  def test_7_android
    return if not $metasm_present
    plugin = Bgo::Application::PluginManager::find('Metasm')
    #proj, f, p = load_target_file '' 
  end

  def test_8_rom
    return if not $metasm_present
    plugin = Bgo::Application::PluginManager::find('Metasm')
    #proj, f, p = load_target_file '' 
  end

  def test_9_shellcode
    return if not $metasm_present
    plugin = Bgo::Application::PluginManager::find('Metasm')
    #proj, f, p = load_target_file 'a_shell32'
    #proj, f, p = load_target_file 'shellcode32'
  end
=end

  def test_9999_shutdown
    #Bgo::Application::PluginManager.shutdown Bgo::Application.lightweight
  end

  # ----------------------------------------------------------------------
  def load_target_file(target_file)
    proj = Bgo::Project.new
    fname = path_to_target target_file
    # create TargetFile
    f = proj.add_file(fname)
    assert_not_nil(f)
    # create a Process object for TargetFile
    p = proj.add_process fname, fname
    assert_not_nil(p)
    [proj, f, p]
  end

  def path_to_target(target_file)
    File.join TGT_DIR, target_file
  end
end
