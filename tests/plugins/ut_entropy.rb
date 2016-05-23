#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Entropy Plugin

require 'test/unit'
require 'bgo/application/plugin_mgr'

class TC_PluginIdentEntropy < Test::Unit::TestCase
  TGT_DIR = File.dirname(File.dirname(__FILE__)) + File::SEPARATOR + 'targets'

  def test_1_requirements
    Bgo::Application::PluginManager.init
    Bgo::Application::PluginManager.startup Bgo::Application.lightweight
  end

  def test_2_ident
    p = Bgo::Application::PluginManager::find('Entropy')
    assert_not_nil(p)
    assert(p.spec_supported? :ident)

    # test against ELF binary
    fname = TGT_DIR + File::SEPARATOR + 'linux-2.6.x-64.bin'
    buf = File.binread(fname)
    #score = p.spec_rating(:ident, buf, fname)
    id = p.spec_invoke(:ident, buf, fname)
    assert_equal(Bgo::Ident, id.class)
    assert_equal(Bgo::Ident::CONTENTS_CODE, id.contents)
    assert_equal(Bgo::Ident::FORMAT_UNKNOWN, id.format)
    assert_equal('Object code', id.summary)
    assert_equal('unknown', id.mime)

    # test against nulls
    fname = TGT_DIR + File::SEPARATOR + 'ten_nulls.dat'
    buf = File.binread(fname)
    id = p.spec_invoke(:ident, buf, fname)
    assert_equal(Bgo::Ident, id.class)
    assert_equal(Bgo::Ident::CONTENTS_DATA, id.contents)
    assert_equal(Bgo::Ident::FORMAT_UNKNOWN, id.format)
    assert_equal('Uninitialized data', id.summary)
    assert_equal('unknown', id.mime)

    # test against ASCII
    id = p.spec_invoke(:ident, 'A man, a plan, a canal -- Panama!', '')
    assert_equal(Bgo::Ident::CONTENTS_DATA, id.contents)
    assert_equal(Bgo::Ident::FORMAT_UNKNOWN, id.format)
    assert_equal('Plaintext', id.summary)
    assert_equal('unknown', id.mime)

    # test against random data
    buf = Array.new(100) { rand(256) }.pack('C*')
    id = p.spec_invoke(:ident, buf, '')
    assert_equal(Bgo::Ident::CONTENTS_DATA, id.contents)
    assert_equal(Bgo::Ident::FORMAT_UNKNOWN, id.format)
    assert_equal('Random or compressed data', id.summary)
    assert_equal('unknown', id.mime)
  end

  def test_3_api
    p = Bgo::Application::PluginManager::find('Entropy')
    assert_not_nil(p)
    assert(p.api.include? :entropy)

    # string
    ent = p.entropy "\x00\x11\x00\x11\x00\x11\x00\x11"
    assert_equal(0.125, ent)
    ent = p.entropy "\x00\x00\x00\x11\x00\x11\x00\x11"
    assert_equal(0.119, ent.round(3))
    ent = p.entropy "\x00\x00\x00\x00\x00\x11\x00\x11"
    assert_equal(0.101, ent.round(3))
    ent = p.entropy "\x00\x00\x00\x00\x00\x00\x00\x11"
    assert_equal(0.068, ent.round(3))
    ent = p.entropy "\x00\x00\x00\x00\x00\x00\x00\x00"
    assert_equal(0.0, ent)
    ent = p.entropy "\x00\x11\x22\x33\x44\x55\x66\x77\x88\x99"
    assert_equal(0.415, ent.round(3))

    # array
    ent = p.entropy [0,1,0,1,0,1,0,1]
    assert_equal(0.125, ent)
    ent = p.entropy [0,1,2,3,4,5,6,7,8,9]
    assert_equal(0.415, ent.round(3))
    ent = p.entropy [1,3,5,7,113, 151,257,313,449,521,0]
    assert_equal(0.346, ent.round(3))
  end

  def test_9999_shutdown
    #Bgo::Application::PluginManager.shutdown Bgo::Application.lightweight
  end
end

