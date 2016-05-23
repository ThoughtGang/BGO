#!/usr/bin/env ruby
# :title: Bgo::Commands::ProjectEdit
=begin rdoc
BGO command to modify project contents

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
A command to edit project contents
=end
    class ProjectEditCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Edit BGO project details'
      usage "#{Commands.data_model_usage} [-n name] [-d descr]"
      help "Modify a Project.
Category: plumbing

Options:
  -d, --description string  Set project description
  -n, --name string         Set project name
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

Description:
#{Commands.data_model_help}

Examples:

  # Change name of Project in '~/my_project.bgo' to 'My Project' 
  bgo project-edit -n 'My Project' -p ~/my_project.bgo
  # Change description of detected project to 'Undescribed'
  bgo project-edit -d 'Undescribed'

See also: project, project-create
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        proj = state.project
        if proj
          proj.name = options.name if options.name
          proj.descr = options.descr if options.descr

          proj.save("Project '#{proj.name}' modified by cmd PROJECT" )
          true
        else
          $stderr.puts "No project found!"
          false
        end
      end

      def self.get_options(args)
        options = super

        options.name = nil    # default project name
        options.descr = nil   # default project description

        opts = OptionParser.new do |opts|
          opts.on( '-d', '--description string' ) { |d| options.descr = d }
          opts.on( '-n', '--name string' ) { |n| options.name = n }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        return options
      end

    end

  end
end

