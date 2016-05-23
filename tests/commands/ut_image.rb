#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO image commands

require 'test/unit'
require 'bgo/application/command'
require 'bgo/image'

class TC_CommandImage < Test::Unit::TestCase

  def test_1_image
    cmd = Bgo::Application::Command.load_single('image-create')
    assert_not_nil(cmd)
    assert_equal('image-create', cmd.command_name)

    orig_img = Bgo::Image.new("\xCC\xCC\xCC")
    state = cmd.invoke_returning_state(['-x', 'CC CC CC'])
    img = state.images.first
    assert_not_nil(img)
    assert_equal(orig_img.digest, img.digest)
    assert_equal(orig_img.contents, img.contents)

    path = File.join File.dirname(File.dirname(__FILE__)), 'targets', 
           'linux-2.6.x-64.bin'
    buf = File.binread(path)
    orig_img = Bgo::Image.new(buf)
    state = cmd.invoke_returning_state([path])
    img = state.images.first
    assert_not_nil(img)
    assert_equal(orig_img.digest, img.digest)
    assert_equal(orig_img.contents, img.contents)
  end

  def test_2_virtual_image
    cmd = Bgo::Application::Command.load_single('image-create-virtual')
    assert_not_nil(cmd)
    assert_equal('image-create-virtual', cmd.command_name)

    orig_img = Bgo::VirtualImage.new( "\xCC", 3 )

    state = cmd.invoke_returning_state(['-s', '3', '-x', 'CC'])
    img = state.images.first
    assert_not_nil(img)
    assert_equal(orig_img.digest, img.digest)
    assert_equal(orig_img.contents, img.contents)

    state = cmd.invoke_returning_state(['-s', '3', '-x', 'CC CC CC'])
    img = state.images.first
    assert_not_nil(img)
    assert_equal(orig_img.digest, img.digest)
    assert_equal(orig_img.contents, img.contents)

    orig_img = Bgo::VirtualImage.new( '0', 1024 )
    state = cmd.invoke_returning_state(['0'])
    img = state.images.first
    assert_not_nil(img)
    assert_equal(orig_img.digest, img.digest)
    assert_equal(orig_img.contents, img.contents)

    # TODO: check octal
  end

  def test_3_remote_image
    #cmd = Bgo::Application::Command.load_single('image-create-remote')
    #assert_not_nil(cmd)
    #assert_equal('image-create-remote', cmd.command_name)
    #Bgo::RemoteImage.new(path, size, ident)
  end
end

