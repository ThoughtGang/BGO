#!/usr/bin/env ruby                                                             
# :title: Bgo::Commands::HumanReadable
=begin rdoc
Shared methods for commands that format output

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

module Bgo
  module Commands


=begin rdoc
Covert Fixnum to a string in human-readable format (1K, 100M, 2.1G).
Name is taken from ls -l.
=end
    def self.human_size_str(num)
      code = [ '', 'K', 'M', 'G', 'T', 'P']
      carry = 0
      dec = ''

      loop do
        n = num / 1024
        break if n < 1

        rem = ((num % 1024) / 102.4).round
        if rem > 0
          carry = 1
          dec = ".#{rem}"
        end

        code.shift
        num = n
      end

      if num > 10
        num += carry
        dec = ''
      end

      "#{num}#{dec}#{code.shift}"
    end

  end
end
