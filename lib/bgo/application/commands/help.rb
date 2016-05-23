#!/usr/bin/env ruby
# :title: Bgo::Commands::Help
=begin rdoc
BGO Help command

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'

module Bgo
  module Commands

=begin rdoc
A command to print out help text for all other Command objects.
=end
    class HelpCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      disable_pipeline
      summary 'Help command'
      usage '[command]'
      help 'Write help documentation to STDOUT.
Category: porcelain

With no arguments, this lists all available commands along with a brief
summary of each.

A pattern argument, e.g. \'add-*\' or \'h?lp\', will list the commands that
match the pattern along with their summaries.

A command name argument will print the usage string and help documentation 
for that command.
'
# ----------------------------------------------------------------------

      def self.invoke(args)
        pattern = args.length > 0 ? args[0] : '*'
        if pattern !~ /^[-_[:alnum:]]+$/
          # Allow use of * and ? instead of forcing regexes on users
          regex = pattern.gsub('*','.*').gsub('?','.?')
          help_regexp( /#{regex}/ )
        else
          help_name( pattern )
        end
      end

      def self.help_regexp(pattern)
        cmds = Bgo::Application::Command.load_matching(pattern)
        cmds.keys.sort.each{|name| puts "%-20s %s" % [name, cmds[name].summary]}
      end

      def self.help_name(name)
        cls = Bgo::Application::Command.load_single(name)
        if cls
          puts "#{name} #{cls.usage}"
          puts "#{cls.help}"
        else
          puts "Command '#{name}' not found."
        end
      end

    end

  end
end

