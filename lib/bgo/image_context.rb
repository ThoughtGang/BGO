#!/usr/bin/env ruby
# :title: Bgo::ImageContext
=begin rdoc
BGO ImageContext module.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo' # auto-load BGO datamodel classes as-needed 

require 'bgo/block'
require 'bgo/scope'
#require 'bgo/reference'

# TODO:
#        to_h invoked by all derived classes
#        block mgt
#        scope mgt
#        ref mgt

module Bgo

# =============================================================================
=begin rdoc
ModelItem tied to an Image and manager of bytecontainer: a File or Process.
=end
  module ImageContextObject

    attr_reader :scope
    attr_reader :block
    attr_reader :references

=begin rdoc
Initialize ImageContext instance.
This must be called in the initialize() method of ImageContext classes.
=end
    def image_context_init
      # @references =
      # @scope =
      # @block =
    end

    # TODO: symbols(rev) : return list of all symbol objects or ident + name
    #                      recursing children of scope

    def to_hash
      # TODO: handle refs, scope, block
      {}
    end
    alias :to_h :to_hash

    # from_h?

  end

end
