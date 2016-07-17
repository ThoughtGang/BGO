#!/usr/bin/env ruby
# :title: Magic Plugin
=begin rdoc
BGO Magic ident plugin

Copyright 2032 Thoughtgang <http://www.thoughtgang.org>

A data identification plugin based on libmagic.
NOTE: This requires the Magic gem from https://rubygems.org/gems/Magic .
=end

require 'bgo/application/plugin'
require 'bgo/ident'
require 'bgo/plugins/shared/ident/magic'

# External packages may not be present! this will cause a load error.
require 'rubygems'
require 'Magic'

module Bgo
  module Plugins
    module Ident

      class MagicIdent
        extend Bgo::Plugin

        # ----------------------------------------------------------------------
        # DESCRIPTION
        name 'Magic-ident'
        author 'dev@thoughtgang.org'
        version '1.0'
        description 'Identification of File or String data based on libmagic.'
        help 'Magic Ident Plugin
Identify contents of a File or String using libmagic.
Requires gem "Magic" from  https://rubygems.org/gems/Magic.'

        # ----------------------------------------------------------------------
        # SPECIFICATIONS
        spec :ident, :do_ident, 50 do |buf, path|
          # Note: we use 75 for a max to allow other plugins to push themselves
          #       to 100 if they are super-confident (e.g. they fill ArchInfo)
          confidence = (buf.kind_of? String) ? 50 : 75
          ident = identify( buf )
          confidence -= 10 if ident.format == 'data'
          confidence -= 10 if ident.format == 'ASCII'
          confidence -= 25 if ident.mime == 'application/octet-stream'
          confidence -= 25 if ident.mime == 'text/plain'
          confidence
        end

        def do_ident( buf, path )
          identify( buf )
        end

        # ----------------------------------------------------------------------
        # API

        api_doc :identify, ['IO|buffer target'], 'Bgo::Ident', \
                'Get \'magic\' ident Hash for target. Note: this will return a more complete result for a File than a String.'
        def identify(tgt)
          # Note: libmagic CLOSES THE FILE DESCRIPTOR PASSED TO IT. We therefore
          #       create two copies of the target if it is an IO object.
          tgt_a = (tgt.respond_to? :path) ? File.open(tgt.path, 'rb') : tgt
          tgt_b = (tgt.respond_to? :path) ? File.open(tgt.path, 'rb') : tgt

          ident = ::Magic::identify(tgt_a)
          mime = ::Magic::identify(tgt_b, :mime => true )
          Plugins::Ident::Magic.generate_ident(ident, mime)
        end

      end

    end
  end
end
