#!/usr/bin/env ruby
# :title: Bgo::Commands::Project
=begin rdoc
BGO command to show and modify project contents

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/project'

module Bgo
  module Commands

=begin rdoc
A command to show project contents
=end
    class ProjectCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      end_pipeline
      summary 'View BGO project details'
      usage "#{Commands.data_model_usage} [-dn] [--info]"
      help "View a Project.
Category: porcelain

Options:
  -n, --name                  Show project name
  -d, --description           Show project description
  --full                      Produce detailed output
  --info                      Show project creation details
#{Commands.standard_options_help}
#{Commands.data_model_options_help}
Note: The --stdout option has no effect in this command.

Description:
#{Commands.data_model_help}

Examples:
  # View the details for the project in '~/my_project.bgo'
  bgo project -p ~/my_project.bgo

  # View the full details for the project in ., including the description
  bgo project --info -d

See also: project-create, project-edit
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        proj = state.project
        if proj
          show_name(proj, options) if options.show_name
          show_info(proj, options) if options.show_info
          show_descr(proj, options) if options.show_descr
          show_branches(proj, options) if options.show_branches
          show_current(proj, options) if options.show_current
          true
        else
          $stderr.puts "No project found!"
          false
        end
      end

      def self.get_options(args)
        options = super

        options.details = false
        options.show_info = false
        options.show_name = false
        options.show_descr = false

        opts = OptionParser.new do |opts|
          opts.on( '-d', '--description' ) { options.show_descr = true }
          opts.on( '-n', '--name' ) { options.show_name = true }
          # TODO: branches, current
          opts.on( '--info' ) { options.show_info = true }
          opts.on( '--full' ) { select_show_full options }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        # No other show options were selected: show name and info
        select_show_full(options) if ! show_option_selected(options)

        return options
      end

      def self.show_option_selected(options)
        options.show_info || options.show_name || options.show_descr ||
        options.show_branches || options.show_current 
      end

      def self.select_show_full(options)
        options.show_name = options.show_descr = options.show_info = true
        options.details = true
      end

      def self.show_name(proj, options)
        puts "#{options.details ? 'Name: ' : ''}#{proj.name}"
      end

      def self.show_descr(proj, options)
        puts "#{options.details ? 'Description: ' : ''}#{proj.description}"
      end

      def self.show_info(proj, options)
        puts "#{options.details ? 'Created: ' : ''}#{proj.created}"
        puts "#{options.details ? 'BGO Version: ' : ''}#{proj.bgo_version}"
      end
    end

  end
end

