#!/usr/bin/env ruby
# :title: Bgo::Commands::TargetDisasm
=begin rdoc
BGO command to load and disassemble one or more on-disk files.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/standard_options'
require 'bgo/application/commands/shared/plugin'

require 'bgo/project'
require 'bgo/application/git/project'

# * in-pipeline: add files to project, create process if necessary, run plugin
# * standalone: create process, create files, run plugin
# * standalone (--create-project): create project, then perform above

module Bgo
  module Commands

=begin rdoc
A command to load and disassemble one or more files. This will create a Project
and a Process.
=end
    class TargetDisasmCommand < Application::Command
# ----------------------------------------------------------------------
      summary 'load disasm files or binary strings then disasm'
      usage "[-P id] #{Commands.data_model_usage} #{Commands.plugin_usage} FILE [...]"
      help ".
Category: porcelain

Options:
  -P, --pid ident           Process ident 
#{Commands.plugin_options_help}
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

Description:

If process is not specified or does not exist, a new process will be created.

If project is specified but does not exist, it will be created.
        $TG_PLUGIN_DEBUG = true

#{Commands.data_model_help}

Examples:
  bgo target-disasm ...

See also: project-create, disasm-bytes, load-target"
# ----------------------------------------------------------------------

      # Note: invoke_with_state is not used in order to manage project creation
      def self.invoke(args)
        options = get_options(args)

        # create project if a path was specified but the project does not exist
        if options.project_path &&
           (! Bgo::Git::Project.valid_project? options.project_path)
            name = File.basename(options.project_path)
            Bgo::Git::Project.create(options.project_path, name)
        end

        state = Pipeline.factory( File.basename(__FILE__, '.rb'), options )

        if (! state.project )
          # create a project object in the Pipeline working data area
          state.working_data[:project] = Bgo::Project.new
        end

        p = get_process(state, options)
        files = options.file_paths.map { |path| state.add_file(path) }
        invoke_load_target(p, files, options, state)

        state.to_stdout if (state.required? options)

        true
      end

      def self.get_process(state, options)
        cmd = File.basename(options.file_paths.first)
        ident = options.proc_ident
        p = ident ? state.process(options.proc_ident) : nil
        p || state.add_process(cmd, cmd, nil, ident)
      end

      def self.invoke_load_target(p, files, options, state)
        options.plugin_opts = {} if (! options.plugin_opts.kind_of? Hash)
        args = [p, files, options.plugin_opts]
        plugin = Commands.plugin_for_spec(:load_target, options.plugin, *args)
        if ! plugin
          $stderr.puts "Unable to find a plugin supporting :load_target"
          return
        end

        plugin.spec_invoke(:load_target, *args)
        state.save("TARGET-DISASM command using plugin #{plugin.canon_name}")
      end

      def self.get_options(args)
        options = super
        options.proc_ident = nil
        options.file_paths = []

        opts = OptionParser.new do |opts|
          opts.on( '-P', '--pid ident' ) { |id| options.proc_ident = id }

          Commands.plugin_options(options, opts)
          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)
        options.file_paths += args

        return options
      end

    end

  end
end

