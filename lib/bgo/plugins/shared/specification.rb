#!/usr/bin/env ruby
# :title: Bgo::Plugin::Specification
=begin rdoc
Standard Plugin Specifications

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>

This directory contains Specification definitions used by standard BGO
plugins.

Each Specification definition is an instance of the Specification class.

Example:

Bgo::Plugin::Specification.new( :unary_operation, 'fn(x)', [[Fixnum,String]], [Fixnum,String] )

The list of all Specification definitions can be obtained via
Bgo::Plugin::Specification.specs().
=end

module Bgo
  module Plugin

=begin rdoc
Namespace for defining Specification objects.  Just in case.
=end
    module Spec
    end

  end
end

Dir.foreach(File.join(File.dirname(__FILE__), 'specification')) do |f|
  # FIXME: search plugin dirs for shared/specification files
  require File.join('bgo', 'plugins', 'shared', 'specification',
                    File.basename(f, '.rb')) if (f.end_with? '.rb')
end
