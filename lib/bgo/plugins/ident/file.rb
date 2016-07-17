#!/usr/bin/env ruby
# :title: File Plugin
=begin rdoc
BGO File ident plugin

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

A data identification plugin based on the UNIX file(1) command.
=end


require 'bgo/application/plugin'
require 'bgo/ident'
require 'bgo/plugins/shared/ident/magic'
require 'bgo/plugins/shared/tempfile'

require 'shellwords'

raise LoadError, 'file(1) is not installed' if `which file`.chomp.empty?

module Bgo
  module Plugins
    module Ident
  
      class File1
        extend Bgo::Plugin

        # ----------------------------------------------------------------------
        # DESCRIPTION
        name 'file-1-ident'
        author 'dev@thoughtgang.org'
        version '1.0'
        description 'Identification of file or buffer data via file(1).'
        help 'Runs file(1) command on a path or buffer.'

        # ----------------------------------------------------------------------
        # SPECIFICATIONS
        spec :ident, :do_ident, 50 do |buf, path|
          next 0 if `which file`.empty?       # file(1) not installed (! unix?)
          next 0 if ! (File.exist? path)      # cannot handle data in 'buf'
          ident = identify_file(path)
          confidence = 40
          confidence -= 10 if ident.format == 'data'
          confidence -= 10 if ident.format == 'ASCII'
          confidence -= 25 if ident.mime == 'application/octet-stream'
          confidence -= 25 if ident.mime == 'text/plain'
          confidence
        end

        # NOTE: path argument is ignored - a tempfile is created if need be.
        def do_ident( tgt, path )
          return identify_file( buf.path ) if (tgt.respond_to? :path) and \
                                           tgt.path   # StringIO has nil path
          buf = (tgt.respond_to? :read) ? tgt.read : tgt
          Bgo.tmpfile_for_buffer(buf, 'ident-file') {|f| identify_file(f.path) }
        end
        
        # ----------------------------------------------------------------------
        # API

        api_doc :identify_file, ['String path'], 'Bgo::Ident', \
                'Get \'magic\' ident Hash for file at path'
        def identify_file(path)
          safe_fname = Shellwords.escape(path)
          full = %x{file -p -b #{safe_fname}}.chomp
          summary = full.split(",").first
          mime = %x{file -p -b --mime #{safe_fname}}.chomp
          mime_type, encoding = mime.split('; charset=')
          ctype = Plugins::Ident::Magic.content_type(full.strip, mime_type)
          Bgo::Ident.new(ctype, summary, full, mime_type, encoding)
        end
      end

    end
  end
end

