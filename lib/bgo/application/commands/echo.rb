#!/usr/bin/env ruby
# :title: Bgo::Commands::Echo
=begin rdoc
BGO Echo command

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'

module Bgo
  module Commands

=begin rdoc
An echo command for testing the command system
=end
    class EchoCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      disable_pipeline
      summary 'Print all arguments to STDOUT'
      usage '[ARG] [...]'
      help 'This command prints its arguments to STDOUT.
Category: porcelain
      
This command does not modify a Project or perpetuate a Pipeline. It is mainly 
used for testing.

Examples:
  bgo echo This is a test.

See also: n/a
'
# ----------------------------------------------------------------------

      def self.invoke(args)
        puts args.join ' '
      end

    end

  end
end

