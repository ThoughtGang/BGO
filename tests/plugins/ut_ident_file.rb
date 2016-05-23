#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Ident File Plugin

require 'test/unit'
require 'bgo/ident'
require 'bgo/application/plugin_mgr'

class TC_PluginIdentFile < Test::Unit::TestCase
  TGT_DIR = File.dirname(File.dirname(__FILE__)) + File::SEPARATOR + 'targets'

  def test_1_init
    Bgo::Application::PluginManager.init
    Bgo::Application::PluginManager.startup Bgo::Application.lightweight
  end

  def test_2_file
    fname = TGT_DIR + File::SEPARATOR + 'linux-2.6.x-64.bin'
    buf = File.binread(fname)

    p = Bgo::Application::PluginManager.find('file-1-ident')
    assert_not_nil(p)
    assert(p.spec_supported? :ident)

    # test interface
    #score = p.spec_rating(:ident, buf, fname)
    id1 = p.spec_invoke(:ident, buf, fname)

    assert_equal(Bgo::Ident, id1.class)
    assert(id1.recognized?)
    assert(id1.summary.start_with? 'ELF 64-bit LSB executable')
    assert_equal('application/x-executable', id1.mime)
    assert_equal(Bgo::Ident::CONTENTS_CODE, id1.contents)

    # test API call
    assert( p.api.keys.include? :identify_file )
    id2 = p.identify_file fname
    assert_equal(Bgo::Ident, id2.class)
    assert_equal(id1.inspect, id2.inspect)

    # test on a bunch of nulls
    fname = TGT_DIR + File::SEPARATOR + 'ten_nulls.dat'
    buf = File.binread(fname)
    id = p.spec_invoke(:ident, buf, fname)
    assert_equal('data', id.summary)
    assert_equal('data', id.full)
    assert_equal('application/octet-stream', id.mime)
    assert_equal(Bgo::Ident::CONTENTS_DATA, id.contents)

    # tests for unrecognized data 
    # NOTE: need some data which is not recognized! file(1) defaults to 'data'.
    #assert((not id.recognized?))
    #assert_equal(Bgo::Ident::FORMAT_UNKNOWN, id.format)
  end

  def test_9999_shutdown
    #Bgo::Application::PluginManager.shutdown Bgo::Application.lightweight
  end
end

