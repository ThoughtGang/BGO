#!/usr/bin/env ruby
# :title: ISA namespace
=begin rdoc
Support for Instruction Set Architectures
Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/isa'

# load all supported architectures
Dir.foreach(File.join(File.dirname(__FILE__), 'isa')) do |f|
  require_relative "isa/#{f}" if (f.end_with? '.rb')
end

