#!/usr/bin/env ruby
# :title: ASCII Ident Plugin
=begin rdoc
BGO ASCII Ident plugin

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>

This serves as a failsafe Ident plugin, in case all others fail.
=end

require 'bgo/application/plugin'
require 'bgo/ident'

module Bgo
  module Plugins
    module Ident

      class Ascii
        extend Bgo::Plugin

        # ----------------------------------------------------------------------
        # DESCRIPTION
        name 'Ascii-ident'
        author 'dev@thoughtgang.org'
        version '1.0'
        description 'Detects presence of non-ASCII bytes in target'
        help 'Determines if a file or buffer is plaintext or binary.'

        # ----------------------------------------------------------------------
        # SPECIFICATIONS
        spec :ident, :do_ident, 10 do |buf, path|
          10
        end

        # ----------------------------------------------------------------------
        # API
        FMT_CHARS = [0x09, 0x0A, 0x0B, 0x0D]
        api_doc :is_ascii_byte?, ['Integer'], 'Boolean', \
                'Returns true is argument is a printable ASCII character'
        def is_ascii_byte?(num)
          (num >= 0x20 && num <= 0x7E) || (FMT_CHARS.include? num)
        end
        
        def do_ident(buf, path)
          is_text = false
          buf.each_byte { |b| is_text |= (is_ascii_byte? b) }
          contents = is_text ? Bgo::Ident::CONTENTS_DATA : 
                               Bgo::Ident::CONTENTS_CODE
          summary = full = is_text ? 'plaintext' : 'binary data'
          mime_type = is_text ? 'text/plain' : 'binary/octet-stream'
          Bgo::Ident.new(contents, summary, full, mime_type)
        end

      end

    end
  end
end
