#!/usr/bin/env ruby
# :title: Bgo::ObjectType
=begin rdoc
BGO Object Types
This provides the base classes for the BGO type system.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

module Bgo

=begin rdoc
An object type, i.e. a sequence of bytes that contain structured data.
Subclasses will include:
  * scalar : A scalar data type, e.g. primitives such as Integer
  * string : A character string
  * composite : A structure or record data type
  * array : Multiple instances if a single object type
  * union : Multiple object types sharing the same space
  * class : A structure or record, associated with a mthod table
=end
  class ObjectType
    # size
    # composite?
    # scalar?
    # array? # note any object pointer can be considered an array
  end

=begin rdoc
An instance of an ObjectType, generally used as the contents for a data
Address object.
=end
  class ObjectInstance
    # value
    # ctor taking address.bytes 
  end
end
