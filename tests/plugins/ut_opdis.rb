#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Opdis Plugin

require 'test/unit'
require 'bgo/application/plugin_mgr'

require 'bgo/file'
require 'bgo/image'
require 'bgo/process'
require 'bgo/disasm'

$opdis_present = false

class TC_PluginLoaderOpdis < Test::Unit::TestCase
  TGT_DIR = File.dirname(File.dirname(__FILE__)) + File::SEPARATOR + 'targets'

  def test_1_requirements
    begin
      require 'Opdis'
      $opdis_present = true
    rescue LoadError
      $stderr.puts "Could not find Opdis gem: not running tests."
    end

    return if (! $opdis_present)

    Bgo::Application::PluginManager.init
    Bgo::Application::PluginManager.startup Bgo::Application.lightweight
  end

  # ----------------------------------------------------------------------
  def test_2_opdis
    proj, f, p = load_target_file 'linux-2.6.x-64.bin'

    return if not $opdis_present

    proj, f, p = load_target_file 'linux-2.6.x-64.bin'
    p.load! f
    
    plugin = Bgo::Application::PluginManager::find('Opdis')
    assert_not_nil(plugin)

    p.maps.each do |m|
      next if (! m.flags.include? Bgo::Map::FLAG_EXEC)
      # Create a disassembly task
      task = Bgo::LinearDisasmTask.new(m.start_addr, nil, {}) 

      addrs = plugin.spec_invoke( :disassemble, task, m ) if m.executable?

      #addrs.keys.sort.each do |vma|
        #$stderr.puts addrs[vma].ascii
      #end
      # TODO: actual unit tests
    end
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
