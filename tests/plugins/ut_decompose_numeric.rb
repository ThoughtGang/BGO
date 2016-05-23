#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO DecomposeNumeric Plugin

require 'test/unit'
require 'bgo/application/plugin_mgr'

class TC_PluginIdentDecomposeNumeric < Test::Unit::TestCase
  TGT_DIR = File.dirname(File.dirname(__FILE__)) + File::SEPARATOR + 'targets'

  def test_1_init
    Bgo::Application::PluginManager.init
    Bgo::Application::PluginManager.startup Bgo::Application.lightweight
  end

  def test_2_decompose_numeric_api
    p = Bgo::Application::PluginManager::find('Decompose-Numeric')
    assert_not_nil(p)
    assert(p.api.include? :decompose_numeric)

    # construct keys for every possible permutation
    sz1 = %w{ uint_1byte_0 sint_1byte_0 }
    sz2 = %w{ uint_2byte_big_ uint_2byte_lit_ sint_2byte_big_ sint_2byte_lit_ 
           }.inject([]) { |arr, s| 2.times { |x| arr << s + x.to_s }; arr }
    sz4 = %w{ uint_4byte_big_ uint_4byte_lit_ sint_4byte_big_ sint_4byte_lit_ 
              float_4byte_big_ float_4byte_lit_ 
           }.inject([]) { |arr, s| 4.times { |x| arr << s + x.to_s }; arr }
    sz8 = %w{ uint_8byte_big_ uint_8byte_lit_ sint_8byte_big_ sint_8byte_lit_
              float_8byte_big_ float_8byte_lit_
           }.inject([]) { |arr, s| 8.times { |x| arr << s + x.to_s }; arr }
    keys = sz1 + sz2 + sz4 + sz8

    #test against nulls
    fname = TGT_DIR + File::SEPARATOR + 'ten_nulls.dat'
    buf = File.binread(fname)
    h = p.decompose_numeric(buf)
    assert_equal(keys.count, h.keys.count)
    assert_equal(keys.sort, h.keys.sort)

    # NOTE: This is not a great test (all zeros) -- it just checks structure.
    # verify single-byte numeric primitives: ten 0 bytes
    assert_equal( [0] * 10, h[sz1[0]] )
    assert_equal( [0] * 10, h[sz1[1]] )
    # verify 2-byte numeric primitives: four 0 bytes and one nil or 0 byte
    4.times do |x|
      assert_equal( [0] * 5, h[sz2[x * 2]] )              # 0, 2, 4, 6, 8
      assert_equal( (([0] * 4) << nil), h[sz2[(x*2)+1]] ) # 1, 3, 5, 7, !9
    end
    # verify 4-byte numeric primitives : 0 0 or 0 nil
    6.times do |x|
      3.times { |y| assert_equal( [0, 0], h[sz4[(x*4)+y]] ) }  # 0,4; 1,5; 2,6
      assert_equal( [0, nil], h[sz4[(x*4)+3]] )                # ...the rest
    end
    # verify 8-byte numeric primitives: 0 or nil 
    6.times do |x|
      3.times { |y| assert_equal( [0], h[sz8[(x*8)+y]] ) }     # 0-7, 1-8, 2-9
      5.times { |y| assert_equal( [nil], h[sz8[(x*8)+y+3]] ) } # ...the rest
    end
    
    # byte
    buf = "\x01"
    h = p.decompose_numeric(buf)
    assert_equal({"uint_1byte_0"=>[1], "sint_1byte_0"=>[1]}, h)
    # two-byte
    buf = "\x00\x01"
    h = p.decompose_numeric(buf)
    test_h = {"uint_1byte_0"=>[0, 1], "sint_1byte_0"=>[0, 1], 
              "uint_2byte_big_0"=>[1], "uint_2byte_lit_0"=>[256], 
              "sint_2byte_big_0"=>[1], "sint_2byte_lit_0"=>[256], 
              "uint_2byte_big_1"=>[nil], "uint_2byte_lit_1"=>[nil], 
              "sint_2byte_big_1"=>[nil], "sint_2byte_lit_1"=>[nil] }
    assert_equal(test_h, h)

    buf = "\x01\x00"
    test_h = {"uint_1byte_0"=>[1, 0], "sint_1byte_0"=>[1, 0], 
              "uint_2byte_big_0"=>[256], "uint_2byte_lit_0"=>[1], 
              "sint_2byte_big_0"=>[256], "sint_2byte_lit_0"=>[1], 
              "uint_2byte_big_1"=>[nil], "uint_2byte_lit_1"=>[nil], 
              "sint_2byte_big_1"=>[nil], "sint_2byte_lit_1"=>[nil]}
    h = p.decompose_numeric(buf)
    assert_equal(test_h, h)

    # four-byte
    buf = "\x00\x00\x00\x01"
    test_h = {"uint_1byte_0"=>[0, 0, 0, 1], "sint_1byte_0"=>[0, 0, 0, 1], 
              "uint_2byte_big_0"=>[0, 1], "uint_2byte_lit_0"=>[0, 256], 
              "sint_2byte_big_0"=>[0, 1], "sint_2byte_lit_0"=>[0, 256], 
              "uint_2byte_big_1"=>[0, nil], "uint_2byte_lit_1"=>[0, nil], 
              "sint_2byte_big_1"=>[0, nil], "sint_2byte_lit_1"=>[0, nil], 
              "uint_4byte_big_0"=>[1], "uint_4byte_lit_0"=>[16777216], 
              "sint_4byte_big_0"=>[1], "sint_4byte_lit_0"=>[16777216], 
              "float_4byte_big_0"=>[1.401298464324817e-45], 
              "float_4byte_lit_0"=>[2.350988701644575e-38], 
              "uint_4byte_big_1"=>[nil], "uint_4byte_lit_1"=>[nil], 
              "sint_4byte_big_1"=>[nil], "sint_4byte_lit_1"=>[nil], 
              "float_4byte_big_1"=>[nil], "float_4byte_lit_1"=>[nil], 
              "uint_4byte_big_2"=>[nil], "uint_4byte_lit_2"=>[nil], 
              "sint_4byte_big_2"=>[nil], "sint_4byte_lit_2"=>[nil], 
              "float_4byte_big_2"=>[nil], "float_4byte_lit_2"=>[nil], 
              "uint_4byte_big_3"=>[nil], "uint_4byte_lit_3"=>[nil], 
              "sint_4byte_big_3"=>[nil], "sint_4byte_lit_3"=>[nil], 
              "float_4byte_big_3"=>[nil], "float_4byte_lit_3"=>[nil]}
    h = p.decompose_numeric(buf)
    assert_equal(test_h, h)

    buf = "\x01\x00\x00\x00"
    test_h = {"uint_1byte_0"=>[1, 0, 0, 0], "sint_1byte_0"=>[1, 0, 0, 0], 
      "uint_2byte_big_0"=>[256, 0], "uint_2byte_lit_0"=>[1, 0], 
      "sint_2byte_big_0"=>[256, 0], "sint_2byte_lit_0"=>[1, 0], 
      "uint_2byte_big_1"=>[0, nil], "uint_2byte_lit_1"=>[0, nil],
      "sint_2byte_big_1"=>[0, nil], "sint_2byte_lit_1"=>[0, nil], 
      "uint_4byte_big_0"=>[16777216], "uint_4byte_lit_0"=>[1], 
      "sint_4byte_big_0"=>[16777216], "sint_4byte_lit_0"=>[1], 
      "float_4byte_big_0"=>[2.350988701644575e-38], 
      "float_4byte_lit_0"=>[1.401298464324817e-45], 
      "uint_4byte_big_1"=>[nil], "uint_4byte_lit_1"=>[nil], 
      "sint_4byte_big_1"=>[nil], "sint_4byte_lit_1"=>[nil], 
      "float_4byte_big_1"=>[nil], "float_4byte_lit_1"=>[nil], 
      "uint_4byte_big_2"=>[nil], "uint_4byte_lit_2"=>[nil], 
      "sint_4byte_big_2"=>[nil], "sint_4byte_lit_2"=>[nil], 
      "float_4byte_big_2"=>[nil], "float_4byte_lit_2"=>[nil], 
      "uint_4byte_big_3"=>[nil], "uint_4byte_lit_3"=>[nil], 
      "sint_4byte_big_3"=>[nil], "sint_4byte_lit_3"=>[nil], 
      "float_4byte_big_3"=>[nil], "float_4byte_lit_3"=>[nil]}
    h = p.decompose_numeric(buf)
    assert_equal(test_h, h)

    # 8-byte : bring on the fugly
    buf = "\x00\x00\x00\x00\x00\x00\x00\x01"
    test_h = { "uint_1byte_0"=>[0, 0, 0, 0, 0, 0, 0, 1],
               "sint_1byte_0"=>[0, 0, 0, 0, 0, 0, 0, 1],
               "uint_2byte_big_0"=>[0, 0, 0, 1],
               "uint_2byte_lit_0"=>[0, 0, 0, 256],
               "sint_2byte_big_0"=>[0, 0, 0, 1],
               "sint_2byte_lit_0"=>[0, 0, 0, 256],
               "uint_2byte_big_1"=>[0, 0, 0, nil],
               "uint_2byte_lit_1"=>[0, 0, 0, nil],
               "sint_2byte_big_1"=>[0, 0, 0, nil],
               "sint_2byte_lit_1"=>[0, 0, 0, nil],
               "uint_4byte_big_0"=>[0, 1],
               "uint_4byte_lit_0"=>[0, 16777216],
               "sint_4byte_big_0"=>[0, 1],
               "sint_4byte_lit_0"=>[0, 16777216],
               "float_4byte_big_0"=>[0.0, 1.401298464324817e-45],
               "float_4byte_lit_0"=>[0.0, 2.350988701644575e-38],
               "uint_4byte_big_1"=>[0, nil], "uint_4byte_lit_1"=>[0, nil],
               "sint_4byte_big_1"=>[0, nil], "sint_4byte_lit_1"=>[0, nil],
               "float_4byte_big_1"=>[0.0, nil], "float_4byte_lit_1"=>[0.0, nil],
               "uint_4byte_big_2"=>[0, nil], "uint_4byte_lit_2"=>[0, nil],
               "sint_4byte_big_2"=>[0, nil], "sint_4byte_lit_2"=>[0, nil],
               "float_4byte_big_2"=>[0.0, nil], "float_4byte_lit_2"=>[0.0, nil],
               "uint_4byte_big_3"=>[0, nil], "uint_4byte_lit_3"=>[0, nil],
               "sint_4byte_big_3"=>[0, nil], "sint_4byte_lit_3"=>[0, nil],
               "float_4byte_big_3"=>[0.0, nil], "float_4byte_lit_3"=>[0.0, nil],
               "uint_8byte_big_0"=>[1], "uint_8byte_lit_0"=>[72057594037927936],
               "sint_8byte_big_0"=>[1], "sint_8byte_lit_0"=>[72057594037927936],
               "float_8byte_big_0"=>[5.0e-324],
               "float_8byte_lit_0"=>[7.291122019556398e-304],
               "uint_8byte_big_1"=>[nil], "uint_8byte_lit_1"=>[nil],
               "sint_8byte_big_1"=>[nil], "sint_8byte_lit_1"=>[nil],
               "float_8byte_big_1"=>[nil], "float_8byte_lit_1"=>[nil],
               "uint_8byte_big_2"=>[nil], "uint_8byte_lit_2"=>[nil],
               "sint_8byte_big_2"=>[nil], "sint_8byte_lit_2"=>[nil],
               "float_8byte_big_2"=>[nil], "float_8byte_lit_2"=>[nil],
               "uint_8byte_big_3"=>[nil], "uint_8byte_lit_3"=>[nil],
               "sint_8byte_big_3"=>[nil], "sint_8byte_lit_3"=>[nil],
               "float_8byte_big_3"=>[nil], "float_8byte_lit_3"=>[nil],
               "uint_8byte_big_4"=>[nil], "uint_8byte_lit_4"=>[nil],
               "sint_8byte_big_4"=>[nil], "sint_8byte_lit_4"=>[nil],
               "float_8byte_big_4"=>[nil], "float_8byte_lit_4"=>[nil],
               "uint_8byte_big_5"=>[nil], "uint_8byte_lit_5"=>[nil],
               "sint_8byte_big_5"=>[nil], "sint_8byte_lit_5"=>[nil],
               "float_8byte_big_5"=>[nil], "float_8byte_lit_5"=>[nil],
               "uint_8byte_big_6"=>[nil], "uint_8byte_lit_6"=>[nil],
               "sint_8byte_big_6"=>[nil], "sint_8byte_lit_6"=>[nil],
               "float_8byte_big_6"=>[nil], "float_8byte_lit_6"=>[nil],
               "uint_8byte_big_7"=>[nil], "uint_8byte_lit_7"=>[nil],
               "sint_8byte_big_7"=>[nil], "sint_8byte_lit_7"=>[nil],
               "float_8byte_big_7"=>[nil], "float_8byte_lit_7"=>[nil]}
    h = p.decompose_numeric(buf)
    assert_equal(test_h, h)

    buf = "\x01\x00\x00\x00\x00\x00\x00\x00"
    test_h = { "uint_1byte_0"=>[1, 0, 0, 0, 0, 0, 0, 0],
               "sint_1byte_0"=>[1, 0, 0, 0, 0, 0, 0, 0],
               "uint_2byte_big_0"=>[256, 0, 0, 0],
               "uint_2byte_lit_0"=>[1, 0, 0, 0],
               "sint_2byte_big_0"=>[256, 0, 0, 0],
               "sint_2byte_lit_0"=>[1, 0, 0, 0],
               "uint_2byte_big_1"=>[0, 0, 0, nil],
               "uint_2byte_lit_1"=>[0, 0, 0, nil],
               "sint_2byte_big_1"=>[0, 0, 0, nil],
               "sint_2byte_lit_1"=>[0, 0, 0, nil],
               "uint_4byte_big_0"=>[16777216, 0], "uint_4byte_lit_0"=>[1, 0],
               "sint_4byte_big_0"=>[16777216, 0], "sint_4byte_lit_0"=>[1, 0],
               "float_4byte_big_0"=>[2.350988701644575e-38, 0.0],
               "float_4byte_lit_0"=>[1.401298464324817e-45, 0.0],
               "uint_4byte_big_1"=>[0, nil], "uint_4byte_lit_1"=>[0, nil],
               "sint_4byte_big_1"=>[0, nil], "sint_4byte_lit_1"=>[0, nil],
               "float_4byte_big_1"=>[0.0, nil], "float_4byte_lit_1"=>[0.0, nil],
               "uint_4byte_big_2"=>[0, nil], "uint_4byte_lit_2"=>[0, nil],
               "sint_4byte_big_2"=>[0, nil], "sint_4byte_lit_2"=>[0, nil],
               "float_4byte_big_2"=>[0.0, nil], "float_4byte_lit_2"=>[0.0, nil],
               "uint_4byte_big_3"=>[0, nil], "uint_4byte_lit_3"=>[0, nil],
               "sint_4byte_big_3"=>[0, nil], "sint_4byte_lit_3"=>[0, nil],
               "float_4byte_big_3"=>[0.0, nil], "float_4byte_lit_3"=>[0.0, nil],
               "uint_8byte_big_0"=>[72057594037927936], "uint_8byte_lit_0"=>[1],
               "sint_8byte_big_0"=>[72057594037927936], "sint_8byte_lit_0"=>[1],
               "float_8byte_big_0"=>[7.291122019556398e-304],
               "float_8byte_lit_0"=>[5.0e-324],
               "uint_8byte_big_1"=>[nil], "uint_8byte_lit_1"=>[nil],
               "sint_8byte_big_1"=>[nil], "sint_8byte_lit_1"=>[nil],
               "float_8byte_big_1"=>[nil], "float_8byte_lit_1"=>[nil],
               "uint_8byte_big_2"=>[nil], "uint_8byte_lit_2"=>[nil],
               "sint_8byte_big_2"=>[nil], "sint_8byte_lit_2"=>[nil],
               "float_8byte_big_2"=>[nil], "float_8byte_lit_2"=>[nil],
               "uint_8byte_big_3"=>[nil], "uint_8byte_lit_3"=>[nil],
               "sint_8byte_big_3"=>[nil], "sint_8byte_lit_3"=>[nil],
               "float_8byte_big_3"=>[nil], "float_8byte_lit_3"=>[nil],
               "uint_8byte_big_4"=>[nil], "uint_8byte_lit_4"=>[nil],
               "sint_8byte_big_4"=>[nil], "sint_8byte_lit_4"=>[nil],
               "float_8byte_big_4"=>[nil], "float_8byte_lit_4"=>[nil],
               "uint_8byte_big_5"=>[nil], "uint_8byte_lit_5"=>[nil],
               "sint_8byte_big_5"=>[nil], "sint_8byte_lit_5"=>[nil],
               "float_8byte_big_5"=>[nil], "float_8byte_lit_5"=>[nil],
               "uint_8byte_big_6"=>[nil], "uint_8byte_lit_6"=>[nil],
               "sint_8byte_big_6"=>[nil], "sint_8byte_lit_6"=>[nil],
               "float_8byte_big_6"=>[nil], "float_8byte_lit_6"=>[nil],
               "uint_8byte_big_7"=>[nil], "uint_8byte_lit_7"=>[nil],
               "sint_8byte_big_7"=>[nil], "sint_8byte_lit_7"=>[nil],
               "float_8byte_big_7"=>[nil], "float_8byte_lit_7"=>[nil]}
    h = p.decompose_numeric(buf)
    assert_equal(test_h, h)
  end

end

