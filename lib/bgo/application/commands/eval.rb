#!/usr/bin/env ruby
# :title: Bgo::Commands::Eval
=begin rdoc
BGO command to eval() Ruby code on a project or stream

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

module Bgo
  module Commands

=begin rdoc
A command to run arbitrary ruby code on a Project or Stream.
=end
    class EvalCommand < Application::Command
# ----------------------------------------------------------------------
      end_pipeline
      summary 'Execute Ruby code on Pipeline input'
      usage "#{Commands.data_model_usage} [-f str] [STMT...]"
      help "Execute arbitrary Ruby code on an input Project or stream.
Category: plumbing

This command will execute Ruby code after loading the Pipeline object. The
BGO Pipeline object will be available in the global variable $BgoState,
with access to the following members:

  $BgoState.command_history    # Array of previously-executed BGO Commands
  $BgoState.project_path       # Path to Git::Project repo if applicable
  $BgoState.project            # Project object if present
  $BgoState.working_data       # Hash of ModelItem type => Arr of instances

Each STMT argument consists of one or more statements of Ruby (joined by ';')
to be executed. The STMT arguments are evaluated in the order specified.

The filename (-f) argument specifies the name of a file to load and evaluate.
Any number of -f options may be provided; the files will be evaluated in the
order they are specified. Note that these files are not 'executed'; this is,
$0 is never equal to __FILE__. All files will be evaluated before the Ruby
commands.

Options:
  -f, --file             Ruby source file to load and eval
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

NOTE: This command is for not for placement in a Pipeline stream and
will terminate the Pipeline. Use pipeline-eval for Ruby code that should
be executed in the context of a Pipeline.

Examples:
  # Print the results of Pipeline#inspect to STDOUT
  bgo process-create -i 100 -f /bin/ls | bgo eval -r 'puts $BgoState.inspect'

  # Add a comment to a Process
  bgo process-create -i 100 -f /bin/ls '/bin/ls -l' | \
  bgo eval 'puts $BgoState.working_data[:processes][\"100\"].comment=\"test\"'

  # Load module 'custom_analysis', invoke CustomAnalysis#run, and print
  # the results to STDOUT
  bgo process-create -i 100 -f /bin/ls '/bin/ls -l' | \
  bgo pipeline-eval -f custom_analysis.rb 'puts CustomAnalysis.run.inspect'

See also: pipeline-eval, pipeline-history, pipeline-print"
# ----------------------------------------------------------------------

      def self.invoke(args)
        options = get_options(args)
        $BgoState = Pipeline.factory( File.basename(__FILE__, '.rb'), options )

        # load all files
        options.files.each do |path|
          buf = File.open(path) {|f| f.read }
          eval buf if buf && (! buf.empty?)
        end

        # eval all code statements
        options.statements.each { |code| eval code }
        true
      end

      def self.get_options(args)
        options = super
        options.files = []
        options.statements = []
        options.redirect_stdout = true

        opts = OptionParser.new do |opts|
          opts.on( '-f', '--file str' ) { |str| options.files << str }

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

