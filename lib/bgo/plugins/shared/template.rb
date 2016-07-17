#!/usr/bin/env ruby
# :title: Template Plugin
=begin rdoc
BGO Template file for creating plugins

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/plugin'

module Bgo
  module Plugins
    module Generic            # Plugin Namespace : Generic

=begin rdoc
Plugin docstring.
=end
      class APlugin
        extend Bgo::Plugin

        # ----------------------------------------------------------------------
        # DESCRIPTION

        name 'APlugin'
        author 'developer@somewhere.org'
        version '0.1'
        description 'Description of plugin'
        help 'Extended help text'

        # ----------------------------------------------------------------------
        # SPECIFICATIONS

        # specification declarations (see bgo/plugins/shared/specification
        
        # spec :spec_name, :method_name, default_confidence do |args|
        #   calculate_confidence(args)
        # end

        # ----------------------------------------------------------------------
        # API
        
        # methods and such

      end

    end
  end
end
