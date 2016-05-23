#!/usr/bin/env ruby
# :title: Bgo::Commands::PluginEval
=begin rdoc
BGO command to eval() Ruby code on a Pipeline with a specified Plugin loaded

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

module Bgo
  module Commands

=begin rdoc
A command to run arbitrary ruby code on a Project or Stream using a Plugin.
=end
    class PluginEvalCommand < Application::Command
# ----------------------------------------------------------------------
      summary 'Execute Ruby code using a specified Plugin'
      usage "#{Commands.data_model_usage} [-f str] [-ns str] [-rx] [STMT...]"
      help "Execute arbitrary Ruby code using a Plugin.
Category: plumbing

This command will execute Ruby code after loading the Pipeline object and
the specified Plugin. The Plugin object will be available in the global
variable $BgoPlugin. The BGO Pipeline object will be available in the global 
variable $BgoState, with access to the following members:

  $BgoState.command_history    # Array of previously-executed BGO Commands
  $BgoState.project_path       # Path to Git::Project repo if applicable
  $BgoState.project            # Project object if present
  $BgoState.working_data       # Hash of ModelItem type => Arr of instances

The Plugin object is specified by name with the -n option, or by Specification
with the -s argument. With -s, the Plugin with the highest rating for that
Specification is selected. If neither -n or -s is selected, this command
behaves like pipeline-eval.

Each STMT argument consists of one or more statements of Ruby (joined by ';')
to be executed. The STMT arguments are evaluated in the order specified.

The filename (-f) argument specifies the name of a file to load and evaluate.
Any number of -f options may be provided; the files will be evaluated in the
order they are specified. Note that these files are not 'executed'; this is,
$0 is never equal to __FILE__. All files will be evaluated before the Ruby
commands.

Options:
  -f, --file             Ruby source file to load and eval
  -n, --name             Plugin name to load
  -s, --spec             Plugin Specification to meet
  -r, --redirect-stdout  Redirect STDOUT to STDERR
  -x, --exit             Terminate pipeline (do not print JSON to STDOUT)
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

NOTE: By default, this command behaves as a Pipeline stream component. This 
means that writing to STDOUT will corrupt the Pipeline. The -r option will
redirect STDIN to STDOUT; the -x option will terminate the Pipeline, meaning
that the Pipeline will not be serialized to JSON or written to STDOUT.

Examples:

  bgo plugin-eval --no-project-detect -x -n file-1-ident \
                  'puts $BgoPlugin.identify_file(\"/bin/ls\")'

See also: eval, pipeline-eval, plugin-list"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        $BgoState = state

        old_stdout = $stdout if options.redirect_stdout
        $stdout = $stderr if options.redirect_stdout

        # load plugin
        if options.plugin
          $BgoPlugin = Bgo::Application::PluginManager.find options.plugin
        end
        if ! $BgoPlugin && options.spec
          $BgoPlugin = Bgo::Application::PluginManager.providing(options.spec
                                                                ).first[0]
        end

        # load all files
        options.files.each do |path|
          buf = File.open(path) {|f| f.read }
          eval buf if buf && (! buf.empty?)
        end

        # eval all code statements
        options.statements.each { |code| eval code }

        $stdout = old_stdout if options.redirect_stdout
        @continue_pipeline = false if options.kill_pipeline

        true
      end

      def self.get_options(args)
        options = super
        options.files = []
        options.statements = []
        options.plugin = nil
        options.spec = nil
        options.redirect_stdout = true
        options.kill_pipeline = false

        opts = OptionParser.new do |opts|
          opts.on( '-f', '--file str' ) { |str| options.files << str }
          opts.on( '-n', '--name str' ) { |str| options.plugin = str }
          opts.on( '-s', '--spec str' ) { |str| options.spec = str }
          opts.on( '-r', '--redirect-stdout' ) {options.redirect_stdout = true}
          opts.on( '-x', '--exit' ) {options.kill_pipeline = true}

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        while args.length > 0
          options.statements << args.shift
        end

        return options
      end

    end

  end
end

