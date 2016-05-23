#!/usr/bin/env ruby
# :title: Bgo::ObjectType::String
=begin rdoc
BGO String ObjectType

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

module Bgo

=begin rdoc
  * string : A character string
=end
  class StringObjectType
    # size
    def string?; true; end
  end

  class UtfStringObject
  end

=begin rdoc
# TODO: can these be combined into a single class?
=end
  class StringObjectInstance
  end
end
