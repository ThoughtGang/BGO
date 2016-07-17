#!/usr/bin/env ruby
# :title: Bgo::Plugin
=begin rdoc
BGO Plugin ibase classes

Copyright 2016 Thoughtgang <http://www.thoughtgang.org>
=end

require 'tg/plugin.rb'

module Bgo
  PluginObject = TG::PluginObject
  Plugin = TG::Plugin
  Specification = TG::Plugin::Specification

  module Plugin
    def disable_if_not(&block)
      return if not block_given?
      Bgo::Application::PluginManager.blacklist(canon_name) if not block.call
    end

    def disable_if(&block)
      return if not block_given?
      Bgo::Application::PluginManager.blacklist(canon_name) if block.call
    end
  end
end
