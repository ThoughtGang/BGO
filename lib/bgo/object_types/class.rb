#!/usr/bin/env ruby
# :title: Bgo::ObjectType::Class
=begin rdoc
BGO Class ObjectType

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

module Bgo

=begin rdoc
  * class : A structure or record, associated with a mthod table
=end
  class ClassObjectType
    # size
    def class? true; end
  end

=begin rdoc
# TODO: can these be combined into a single class?
=end
  class ClassObjectInstance
  end
end
