#!/usr/bin/env ruby
# :title: Bgo::Commands::ProjectCreate
=begin rdoc
BGO command to create a new project

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/project'

module Bgo
  module Commands

=begin rdoc
A command to create a project
=end
    class ProjectCreateCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Create a new BGO Project'
      usage "#{Commands.data_model_usage} [-n str] [-d str] [PATH]"
      help "Create a Project.
Category: plumbing

Options:
  -d, --description string  Set project description
  -n, --name string         Set project name
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

Description:
  This creates a new BGO Project (i.e. a Git repository). If PATH is not
  provided, the Project is encoded in JSON and written to STDOUT. 

  The name of the Project defaults to 'Untitled', and the description of
  the Project defaults to 'BGO Project'. These may be changed using the
  -n and -d flags.

#{Commands.data_model_help}

Examples:
  # Create the project '~/my_project.bgo'
  bgo project-create ~/my_project.bgo
  # Create a project named 'A Target' and write to JSON stream
  bgo project-create -n 'A Target'

NOTE: In this command, the --stdout flag is overridden by presence of PATH. The
-p flag is overriden by the presence of PATH. The presence of PATH is overridden
by the BGO_DISABLE_GIT_DS environment variable. The --stdin flag has no effect.

See also: project, project-edit"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        if options.new_project_path && (! ENV.include? Env::NO_GIT)
          require 'bgo/application/git/project'
          p = Bgo::Git::Project.create( options.new_project_path, options.name,
                                    options.descr )

        else
          state.working_data[:project] = Bgo::Project.new( options.name, 
                                                           options.descr )
        end
        true
      end

      def self.get_options(args)
        options = super
        options.name = Bgo::Project::DEFAULT_NAME
        options.descr = Bgo::Project::DEFAULT_DESCR

        opts = OptionParser.new do |opts|
          opts.on( '-d', '--description string' ) { |d| options.descr = d }
          opts.on( '-n', '--name string' ) { |n| options.name = n }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        # Get project path from first argument
        options.new_project_path = args.shift

        # Force a new project to always be created
        options.project_detect = false
        options.project_path = nil
        options.stdout = true if (! options.new_project_path) or
                                 (ENV.include? Env::NO_GIT)

        return options
      end

    end

  end
end

