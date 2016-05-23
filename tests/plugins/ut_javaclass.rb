#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Javaclass Plugin
# Requires the javaclass gem
# See https://code.google.com/p/javaclass-rb/


require 'test/unit'
require 'bgo/application/plugin_mgr'

require 'bgo/project'
require 'bgo/process'
require 'bgo/file'

$javaclass_present = false

class TC_PluginLoaderJavaclass < Test::Unit::TestCase
  TGT_DIR = File.dirname(File.dirname(__FILE__)) + File::SEPARATOR + 'targets'

  def test_1_requirements
    begin
      require 'rubygems'
      require 'javaclass'
      $javaclass_present = true
    rescue LoadError
      $stderr.puts "Could not find 'javaclass' gem: not running tests."
    end
    return if not $javaclass_present

    Bgo::Application::PluginManager.init
    Bgo::Application::PluginManager.startup Bgo::Application.lightweight

    plugin = Bgo::Application::PluginManager::find('javaclass')
    assert_not_nil(plugin)
    assert(plugin.spec_supported? :ident)
    assert(plugin.spec_supported? :parse_file)
    assert(plugin.spec_supported? :load_file)
  end

  # ----------------------------------------------------------------------
  def test_2_java
    return if not $javaclass_present
    plugin = Bgo::Application::PluginManager::find('javaclass')
    assert_not_nil(plugin)
    proj, f, p = load_target_file 'Java/HelloWorld.class' 
    f.ident!(plugin)
    assert(f.identified?)
    id = f.ident_info
    #$stderr.puts id.inspect
    f.parse!(plugin)
    #$stderr.puts f.sections.map { |s| s.name }.sort.inspect
    #$stderr.puts f.sections.count
    #plugin.spec_invoke( :load_file, p, f, {} )
    #$stderr.puts p.maps.count
    #$stderr.puts p.maps.map {|m| "%d@0x%X" % [m.size, m.start_addr]}.inspect
    #assert_equal(2, p.maps.count)

    # Jar not directly supported by javaclass -- must unzip?
    #proj, f, p = load_target_file 'Java/HelloWorld.jar' 
    #f.ident!(plugin)
    #assert(f.identified?)
    #id = f.ident_info
    #$stderr.puts "**#{f.name}**"
    #$stderr.puts id.inspect
  end

  # ----------------------------------------------------------------------
  # NOT IMPLEMENTED
=begin
  def test_3_android
    return if not $javaclass_present
    plugin = Bgo::Application::PluginManager::find('javaclass')
    #proj, f, p = load_target_file '' 
  end
=end

  def test_9999_shutdown
    #Bgo::Application::PluginManager.shutdown Bgo::Application.lightweight
  end

  # ----------------------------------------------------------------------
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
