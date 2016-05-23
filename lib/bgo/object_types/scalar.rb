#!/usr/bin/env ruby
# :title: Bgo::ObjectType::Scalar
=begin rdoc
BGO Scalar ObjectType

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

module Bgo

=begin rdoc
  * scalar : A scalar data type, e.g. primitives such as Integer
=end
  class ScalarObjectType
    # size
    def scalar?; true; end
  end

=begin rdoc
# TODO: can these be combined into a single class?
=end
  class ScalarObjectInstance
  end
end
