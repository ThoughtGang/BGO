#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO Process class

require 'test/unit'
require 'bgo/process'
require 'bgo/file'
require 'bgo/image'
require 'bgo/project'

class TC_ProcessTest < Test::Unit::TestCase
  TGT_DIR = File.dirname(File.dirname(__FILE__)) + File::SEPARATOR + 'targets'

  def test_create
    ident, fname, cmd, cmt = 1000, 'a.out', './a.out -v', 'test run of a.out'
    p = Bgo::Process.new(ident, cmd, fname, nil)
    p.comment = cmt

    assert_equal(ident, p.ident)
    assert_equal(fname, p.filename)
    assert_equal(cmd, p.command)
    assert_equal(cmt, p.comment.text)
  end

end

