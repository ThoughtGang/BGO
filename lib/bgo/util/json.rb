#!/usr/bin/env ruby
# :title: Bgo::JsonObject
=begin rdoc
An object that can be serialized to JSON.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'rubygems'
begin
  require 'json/ext'
rescue LoadError
  require 'json'
end

# =============================================================================

module Bgo

=begin rdoc
Classes that support JSON serialization should extend this module.
=end
  module JsonClass

=begin rdoc
Parse JSON data with error handling.

Note: this is just generic JSON parsing code. The classes encoded in the JSON
data must have a json_create method instantiated for it to work.
=end
    def self.from_json(str, allow_instantiation=true)
      begin
        # BUG: :symbolize_names causes object to be returned as a Hash
        #JSON.parse(str, {:symbolize_names => true, :max_nesting => 50})
        JSON.parse(str, :create_additions => allow_instantiation,
                        :symbolize_names => true,
                        :max_nesting => 100)
      rescue JSON::ParserError => e
        $stderr.puts "JSON ERROR : #{e.message}"
        $stderr.puts "JSON INPUT : #{str.inspect}"
      end
    end

=begin rdoc
Instantiate object from JSON representation.
=end
    def from_json(str, allow_instantiation=true)
      JsonClass.from_json str, allow_instantiation
    end

=begin rdoc
JSON callback for instantiating object. This uses the class's from_hash method.
=end
    def json_create(o)
      # for import of 'clean' JSON: from_hash o
      #from_hash(o['data'].inject({}) { |h,(k,v)| h[k.to_sym] = v; h })
      from_hash o
    end
  end

=begin rdoc
Classes that support JSON serialization should include this module.
=end
  module JsonObject

=begin rdoc
Convert the object to JSON. This uses the class's to_h method.
=end
    def to_json(*arr)
      if ( arr.count > 0)
        arr.first.max_nesting = 100
      else
        arr.push( {:max_nesting => 100} )
      end
      # for export to 'clean' JSON: self.to_h
      #{ JSON.create_id => self.class.name, 'data' => self.to_h }.to_json(*arr)
      self.to_h.to_json(*arr)
    end
  end

end
