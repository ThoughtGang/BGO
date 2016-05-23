#!/usr/bin/env ruby
# :title: Entropy Plugin
=begin rdoc
BGO Entropy plugin

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

Determine byte entropy of a String, Array, or IO object. Can be used to 
distinguish between code and data contents.
=end

require 'tg/plugin'
require 'bgo/ident'

# TODO: * information gain (info_gain) method that calls entropy()
#       * Command object to calculate entropy of arbitrary bytes
#       * EntropyObject (EO) for passing to inject?
#       * Add a more featureful API, e.g.:
#         byte_entropy(String|IO, {block_size}) => array of F
#         block_entropy(String|IO, {elem_size}) => array of F
#         generic_entropy(String|IO, {block_size, elem_size, prob_dist}) => EO
#       * determine unpacker based on entropy :
#  hexena.googlecode.com/files/entropy_analysis_encrypted_packed_malware.pdf

module Bgo
  module Plugins
    module Ident

=begin rdoc
Calculate Byte Entropy for Binary data or Arrays of Fixnums.
=end
      class Entropy
        extend TG::Plugin

        # ----------------------------------------------------------------------
        # DESCRIPTION
        name 'Entropy'
        author 'dev@thoughtgang.org'
        version '0.9'
        description 'Calculate entropy for bytes or blocks of bytes.'
        help 'Entropy Plugin
This calculates the byte entropy of a File or String, using a block size of
1024 bytes. The :ident specification can only determine if a file contains
code or data, and is only used as a fallback.
Note: The ident specification is not fully implemented and cannot distinguish
between code and data.'

        # ----------------------------------------------------------------------
        # SPECIFICATIONS
        # NOTE: This does not take a block, as it will never provide accurate
        #       enough information, no matter what the contents of the data.
        spec :ident, :identify, 10

        # ----------------------------------------------------------------------
        # API

        api_doc :identify, ['IO|buffer target'], 'Bgo::Ident', \
                'Calculate Ident based on target entropy' 
        def identify(tgt, path='')
          ident_from_ent entropy(tgt)
        end

=begin rdoc
Calculate entropy for contents of IO, Array, or String object.

Note: passing an Array means that elem_size is ignored. The base value used
for an Array will be the lowest power of two that is higher than Array#max,
but equal to or greater than 2**8 (256).
=end
        api_doc :entropy, ['IO|Array|String target, elem_size=1'], 'Array', 
                'Calculate entropy for target IO, Array, or String'
        def entropy(tgt, elem_size=1)
          # generate base value (all possible combinations of bits)
          base = (tgt.kind_of? Enumerable) ? array_elem_base(tgt) : 
                                             elem_base(elem_size)
          # Convert non-Array tgt to Array of values for entropy calculation
          tgt = tgt.read if tgt.respond_to? :read
          tgt = unpack_buffer(tgt, elem_size) if tgt.kind_of? String
          return nil if (! tgt.kind_of? Enumerable)

          # initialize frequency counters for all occurring values
          counters = tgt.inject({}) { |h, b| h[b] ||= 0; h[b] += 1.0; h }

          # calculate entropy based on frequency
          total = tgt.count.to_f
          counters.inject(0.0) do |ent,(byte, count)|
            p_x = count / total
            ent -= (p_x * log_n(base, p_x)) if p_x != 0
            ent
          end
        end

        # ----------------------------------------------------------------------
        
        # Note: The entropy calc just looks for different values, but does not
        #       care what the values are -- so the value encodings can be used,
        #       without regards to whether the value is signed, int, float, etc
        ELEM_SZ_CODE = {
          1 => 'C*',
          2 => 'S*',
          4 => 'L*',
          8 => 'Q*'
        }

=begin rdoc
Unpack a binary buffer based on an element size. The only valid element sizes
are 1, 2, 4, and 8.
=end
        def unpack_buffer(buf, elem_size=1)
          buf.unpack(ELEM_SZ_CODE[elem_size] || ELEM_SZ_CODE[1])
        end

        def elem_base(elem_size=1)
          elem_size = 1 if ! ELEM_SZ_CODE.include? elem_size
          256 * elem_size                # number of all possible combinations
        end

        def array_elem_base(arr)
          exp = log_n(2, arr.max).ceil
          exp = 8 if exp < 8
          2**exp
        end

=begin rdoc
Return logarithm of 'num' to base 'base'. Allows base to vary, which is
important when using multiple element sizes.
=end
        def log_n(base, num)
          Math.log(num) / Math.log(base)
        end

        # estimated from values in entropy_analysis_encrypted_packed_malware.pdf
        MAX_EMPTY_ENTROPY = 0.001
        MAX_PLAINTEXT_ENTROPY = 0.499
        MIN_CODE_ENTROPY = 0.500
        MAX_CODE_ENTROPY = 0.700
        MIN_COMPRESSED_ENTROPY = 0.710

=begin rdoc
Determine code or data based on entropy
=end
        def ident_from_ent(ent)
          contents = Bgo::Ident::CONTENTS_DATA
          mime_type = Bgo::Ident::FORMAT_UNKNOWN
          summary = 'Binary data'
          full = "Entropy of contents: #{ent.round(5)}"

          # TODO: more sophisticated algorithm to detect text, etc
          # TODO: detect packer (see above paper)
          if ent <= MAX_EMPTY_ENTROPY
            summary = 'Uninitialized data'
          elsif ent <= MAX_PLAINTEXT_ENTROPY
            summary = 'Plaintext'
          elsif ent >= MIN_CODE_ENTROPY and ent <= MAX_CODE_ENTROPY
            contents = Bgo::Ident::CONTENTS_CODE
            summary = 'Object code'
          elsif ent >= MIN_COMPRESSED_ENTROPY
            summary = 'Random or compressed data'
          end

          Bgo::Ident.new( contents, summary, full, mime_type )
        end

      end

    end
  end
end
