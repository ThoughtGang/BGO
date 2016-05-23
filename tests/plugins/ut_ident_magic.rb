#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Ident Magic Plugin

require 'test/unit'
require 'bgo/ident'
require 'bgo/application/plugin_mgr'

class TC_PluginIdentMagic < Test::Unit::TestCase
  TGT_DIR = File.dirname(File.dirname(__FILE__)) + File::SEPARATOR + 'targets'

  def test_1_init
    Bgo::Application::PluginManager.init
    Bgo::Application::PluginManager.startup Bgo::Application.lightweight
  end

  def test_2_magic

    fname = TGT_DIR + File::SEPARATOR + 'linux-2.6.x-64.bin'
    buf = File.binread(fname)

    p = Bgo::Application::PluginManager::find('Magic-ident')
    assert_not_nil(p)
    assert(p.spec_supported? :ident)

    # test interface
    #score = p.spec_rating(:ident, buf, fname)
    id1 = p.spec_invoke(:ident, buf, fname)
    assert_equal(Bgo::Ident, id1.class)
    assert(id1.recognized?)
    assert_equal('ELF', id1.format)
    assert_equal('ELF 64-bit LSB executable', id1.summary)
    assert_equal('application/x-executable', id1.mime)
    assert_equal(Bgo::Ident::CONTENTS_CODE, id1.contents)

    # test API method
    assert( p.api.keys.include? :identify )
    id2 = File.open(fname) { |f| p.identify f }
    assert_equal(Bgo::Ident, id2.class)
    assert(id2.recognized?)
    assert_equal(id1.format, id2.format)
    assert_equal(id1.summary, id2.summary)
    assert_equal(id1.mime, id2.mime)
    assert_equal(id1.contents, id2.contents)

    # test on a bunch of NULLs
    fname = TGT_DIR + File::SEPARATOR + 'ten_nulls.dat'
    buf = File.binread(fname)
    id = p.spec_invoke(:ident, buf, fname)
    assert_equal(Bgo::Ident::FORMAT_UNKNOWN, id.format)
    assert_equal('data', id.summary)
    assert_equal('data', id.full)
    assert_equal('application/octet-stream', id.mime)
    assert_equal(Bgo::Ident::CONTENTS_DATA, id.contents)
  end

  def test_9999_shutdown
    #Bgo::Application::PluginManager.shutdown Bgo::Application.lightweight
  end
end
