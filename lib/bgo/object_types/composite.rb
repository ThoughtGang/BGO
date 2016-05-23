#!/usr/bin/env ruby
# :title: Bgo::ObjectType::Composite
=begin rdoc
BGO Composite ObjectType

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

module Bgo

=begin rdoc
  * composite : A structure or record data type
=end
  class CompositeObjectType
    # size
    def composite?; true; end
  end

=begin rdoc
# TODO: can these be combined into a single class?
=end
  class CompositeObjectInstance
  end
end
