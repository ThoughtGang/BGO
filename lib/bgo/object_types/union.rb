#!/usr/bin/env ruby
# :title: Bgo::ObjectType::Union
=begin rdoc
BGO Union ObjectType

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

module Bgo

=begin rdoc
  * union : Multiple object types sharing the same space
=end
  class UnionObjectType
    # size
    def union?; true; end
    # TODO: methods that return true when scalar, composite, etc?
  end

=begin rdoc
# TODO: can these be combined into a single class?
=end
  class UnionObjectInstance
  end
end
