#!/usr/bin/env ruby
# :title: Bgo::Tag
=begin rdoc
BGO Tag object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/util/json'

module Bgo

# ----------------------------------------------------------------------
=begin rdoc
A Collection of Tags for an object.

Note: A Tag is just a symbol. It can be associated with a description in the 
TagRegistry.
=end
  class TagList < Array

=begin rdoc
Add a Tag to an object.
=end
    def add(sym)
      self << sym if (! include?(sym))
    end

=begin rdoc
Remove tag for 'sym' from TagList.
=end
    def delete(sym)
      self.reject! { |x| x == sym }
    end
  end

# ----------------------------------------------------------------------
=begin rdoc
A collection of all defined Tags. This is just a Hash [ Symbol -> String ] of
Tag symbol to Tag description.
=end
  class TagRegistry < Hash

=begin rdoc
Register a Tag with the TagRegistry.
This just associates a String description with a Symbol tag.
=end
    def register(sym, descr=nil)
      self[sym] ||= descr
    end

    alias :tags :keys
  end

end
