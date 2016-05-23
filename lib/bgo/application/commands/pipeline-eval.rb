#!/usr/bin/env ruby
# :title: Bgo::Commands::PipelineEval
=begin rdoc
BGO command to eval() Ruby code on a Pipeline

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
    class PipelineEvalCommand < Application::Command
# ----------------------------------------------------------------------
      summary 'Execute Ruby code in Pipeline context'
      usage "#{Commands.data_model_usage} [-f str] [-r] [STMT...]"
      help "Execute arbitrary Ruby code in the context of a Project or stream.
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
  -r, --redirect-stdout  Redirect STDOUT to STDERR
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

NOTE: This command is for placement in a Pipeline stream and is not intended
for output. Writing to STDOUT will corrupt the Pipeline and should be avoided.
If Ruby code supplied to pipeline-eval writes to STDOUT, use the -r flag to
redirect it to STDERR. Use the eval command for all Ruby code that should
output to the terminal.

Examples:
  # Print the results of Pipeline#inspect to STDERR 
  bgo process-create -i 1000 -f /bin/ls | \
  bgo pipeline-eval -r 'puts $BgoState.inspect' | \ bgo pipeline-print

  # Add a comment to a Process. Note: this example is silent
  bgo process-create -i 1000 -f /bin/ls '/bin/ls -l' | \
  bgo pipeline-eval \
  '$BgoState.working_data[:processes][\"1000\"].comment=\"eval comment\"' | \
  bgo pipeline-print 

  # Load module 'custom_analysis', invoke TestAnalysis#run, and print
  # the results to STDERR
  bgo process-create -i 1000 -f /bin/ls '/bin/ls -l' | \
  bgo pipeline-eval -r -f custom_analysis.rb 'puts TestAnalysis.run.inspect' | \
  bgo pipeline-print

See also: eval, pipeline-history, pipeline-print"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        $BgoState = state
        old_stdout = $stdout if options.redirect_stdout
        $stdout = $stderr if options.redirect_stdout

        # load all files
        options.files.each do |path|
          buf = File.open(path) {|f| f.read }
          eval buf if buf && (! buf.empty?)
        end

        # eval all code statements
        options.statements.each { |code| eval code }

        $stdout = old_stdout if options.redirect_stdout

        true
      end

      def self.get_options(args)
        options = OpenStruct.new
        options.files = []
        options.statements = []
        options.redirect_stdout = true

        opts = OptionParser.new do |opts|
          opts.on( '-f', '--file str' ) { |str| options.files << str }
          opts.on( '-r', '--redirect-stdout' ) {options.redirect_stdout = true}

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

