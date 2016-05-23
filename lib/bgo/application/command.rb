#!/usr/bin/env ruby
# :title: Bgo::Command
=begin rdoc
BGO Command Base class

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application'
require 'bgo/application/config'
require 'bgo/application/env'
require 'bgo/application/commands/shared/pipeline'

require 'optparse'          # most Commands use these so we define them here.
require 'ostruct'

module Bgo

  module Application

=begin rdoc
A BGO CLI Command.

The commands are passed to the BGO command line utility (bin/bgo); the filename
of the command is its command name.

A command is defined by subclassing Bgo::Application::Command inside the 
Bgo::Commands namespace. The class definition requires some directives in order
to initialize a valid command class:

  summary : One-line description displayed when listing commands via `bgo help`
  usage : One-line usage statement for the command
  help : Multiline help document displayed via `bgo help command-name`.
  disable_plugins : Do not start PluginManager (this reduces startup time)
  disable_pipeline : Do not use JSON pipeline for input or output
  end_pipeline : Do not use JSON pipeline for output

Commands which support a pipeline (i.e., that do not use the disable_pipeline
directive) can be chained together with pipes:
  bgo cmd_a | bgo cmd_b | bgo_cmd_c
The BGO data will be serialized to JSON when entering the pipeline, so the 
output of these commands (and of the pipeline) will be JSON data. A command
which uses the end_pipeline directive is expected to write non-JSON data to
STDOUT. This is generally used to display objects in a human-readable format.

Examples:

  module Bgo
    module Commands

      # Example of a simple command that does not use the Pipeline
      class MyEchoCommand < Application::Command
        disable_pipeline
        summary 'A command to echo its arguments'
        usage 'ARG [...]'
        help 'Print arguments array to STDOUT.
Category: porcelain

See also: echo:'

        def self.invoke(args)
          puts args.inspect
        end
      end

      # Example of a Pipeline command for working on BGO ModelItems
      class MyPipelineCommand < Application::Command
        disable_plugins  # use this if plugins are not needed by command
        end_pipeline     # use this if command terminates a pipeline
        summary 'A command to print a project'
        usage '"#{Commands.data_model_usage} [-v]'
        help 'Print BGO Project object to STDOUT.
Category: porcelain

Options:
  -v, --verbose     Show additional detail
  #{Commands.standard_options_help}
  #{Commands.data_model_options_help}
#{Commands.data_model_help}

Examples:
  bgo my-pipeline-command -v

See also: project'

        # This implements the core functionality of the command.
        def self.invoke_with_state(state, options)
          puts options.verbose ? state.project.inspect : 
                                 state.project.name || ''
          true
        end

        # This parses default options as well as the command-specific -v option
        def self.get_options(args)
          options = super
          options.verbose = false
          opts = OptionParser.new do |opts|
            opts.on( '-v', '--verbose' ) { options.verbose = true }

            Commands.data_model_options(options, opts)
            Commands.standard_options(options, opts)
          end

          opts.parse!(args)
          return options
        end
            
      end
    end
  end
=end
    class Command
      attr_reader :summary, :usage, :help

=begin rdoc
List of commands that have been loaded.
=end
      @commands = []
=begin rdoc
List of command_names that have been loaded.
=end
      @command_names = []

=begin rdoc
List of module paths to search for commands.
=end
      @module_paths = $:.select{|dir| dir !~ /gems/}.uniq.collect{ |x| 
                         File.join(x, 'bgo', 'application', 'commands') }
      # Use ~/.bgo/commands if it exists
      @home_cmd_dir = File.join(File.dirname(Application.config.get_home_dir),
                                'commands')
      @module_paths.unshift @home_cmd_dir if File.exist? @home_cmd_dir
      # if config file has a setting for command_dirs, use it
      (Application.config.framework['command_dirs'] || '').split(':').reverse.each {|p| @module_paths.unshift p}
      # if environment variable for commands is set, use it
      if (Env.set? Env::COMMANDS)
        ENV[Env::COMMANDS].split(':').reverse.each {|p| @module_paths.unshift p}
      end

=begin rdoc
Callback to load a Command subclass into @commands when it is defined.
=end
      def self.inherited(cls)
        @commands << cls

        # provide sane defaults for all class variables
        cls.getter_setter('@command_name', 'UNKNOWN COMMAND')
        cls.getter_setter('@summary', 'No summary provided.')
        cls.getter_setter('@usage', 'No usage string provided.')
        cls.getter_setter('@help', 'No help provided.')
        cls.getter_setter('@plugins_required', true)
        cls.getter_setter('@pipeline_supported', true)
        cls.getter_setter('@continue_pipeline', true)
      end

=begin rdoc
Add a path to @module_paths.
=end
      def self.add_path(path)
        @module_paths << cls
      end

=begin rdoc
Run the specifed command if it exists.
This calls the command's invoke() class method.
=end
      def self.run( command, *args )
        cmd = self.load_single(command)
        cmd ? cmd.invoke(args): false
      end

=begin rdoc
Default invoke() class method for Commands.
This reads the Pipeline State, calls the command's get_options() class method,
calls the command's invoke_with_state() class method (passing a Pipeline object
and an options OpenStruct), and writes the Pipeline object to STDOUT if 
necessary.
=end
      def self.invoke(args)
        options = self.get_options(args)
        state = @pipeline_supported ?
                  Commands::Pipeline.factory( self.command_name, options ) :
                  nil
        rv = self.invoke_with_state(state, options)
        state.to_stdout if (self.continue_pipeline? state, options)
        rv
      end

=begin rdoc
Invoke command and return the Pipeline object representing its state.
This is primarily used for testing and debugging.
Note: If state argument is provided, it is considered the current state of
the pipeline, and will be passed to the command. This is used to simulate a
command pipeline in testing.
=end
      def self.invoke_returning_state(args, state=nil, invoke_with_state=true)
        options = self.get_options(args)
        if state
          state.commands << self.command_name
        else
          state = Commands::Pipeline.factory( self.command_name, options )
        end
        self.invoke_with_state(state, options)
        state
      end

=begin rdoc
Return True if command should write the Pipeline to STDOUT.
=end
      def self.continue_pipeline?(state, options)
        @continue_pipeline && state && \
        ((state.required? options) || (! state.project_path?))
      end

=begin rdoc
Default invoke_with_state() class method for Commands.
This just prints a warning to STDERR.
=end
      def self.invoke_with_state(state, options)
        $stderr.puts "WARNING: Default Command.invoke_with-state() called"
        false
      end

=begin rdoc
Default get_options() class method for Commands.
This returns an empty OpenStruct object.
=end
      def self.get_options(args)
        OpenStruct.new
      end

=begin rdoc
Load a Command subclass with the given name. 'command' is the name of a 
ruby file in $RUBYLIB/bgo/commands.
This works by appending the name of a command to @command_names, then
requiring the ruby file. The command class definition will then append 
the class itself to @commands.

This returns the command object.

NOTE: this clears all previously-loaded commands.
=end
      def self.load_single( command )
        return @commands[@command_names.index(command)] \
               if @command_names.include? command
        # TODO: verify that clearing @commands is necessary
        @commands.clear

        @command_names << command
        self.with_load_path do
          begin
            require command
          rescue LoadError => e
            @command_names.pop

            # For mis-named commands, raise CommandNotFound. The application
            # can then attempt to suggest a correct command name.
            raise CommandNotFoundError, command if e.message =~ /load/

            # Otherwise, this is an error in the script. Propagate the
            # exception for debugging purposes.
            raise e
          end
        end

        obj = @commands.first

        # Set command name to filename
        obj.command_name(File.basename(command))

        obj
      end

=begin rdoc
Load all Command subclasses that match the given pattern. Note that this 
supports primitive globbing ala * and ?, which may interfere with 
regular expressions that include those operators.

NOTE: This does not clear previously-loaded commands.
=end
      def self.load_matching( pat=/.*/ )
        self.with_load_path do
          commands = []

          # Get list of all commands matching pattern
          @module_paths.each do |dir|
            next if not File.exist? dir

            Dir::foreach( dir ) do |file|
              next if ((not file.end_with? '.rb') or file.start_with? '.' or 
                       file !~ pat)
              commands << file.chomp('.rb')
            end
          end

          commands.uniq.sort.each do |cmd|
            next if @command_names.include? cmd
            @command_names << cmd
            begin
              require cmd
            rescue LoadError => e
              $stderr.puts "Unable to load Command #{cmd} : #{e.message}"
            end
          end


        end

        command_list = {}
        @command_names.each_with_index do |name, idx|
          # NOTE: this check is needed for classes already in @commands.
          next if name !~ pat
          command_list[@command_names[idx]] = @commands[idx] if @commands[idx]
        end
        command_list
      end

=begin rdoc
Append a command name to @command_names. This isused when a command has been
defined internally, i.e. not in a standalone file under RUBYLIB/bgo/commands.
Examples include commands that are defined by plugins or in unit-test scripts.
This method must be called immediately before or after the command class
definition.
=end

      def self.load_internal(command)
        @command_names << command
      end

=begin rdoc
Change the Ruby library search path and invoke the provided block.
=end
      def self.with_load_path()
        return if not block_given?

        old_path = $:.dup
        $:.clear
        $:.concat @module_paths
        $:.concat old_path

        yield

        $:.clear
        $:.concat old_path
      end

=begin rdoc
Attribute for defining command summary.
=end
      def self.summary(text=nil)
        getter_setter('@summary', text)
      end

=begin rdoc
Attribute for defining usage (arguments) string.
=end
      def self.usage(text=nil)
        getter_setter('@usage', text)
      end

=begin rdoc
Attribute for defining help documentation.
=end
      def self.help(text=nil)
        getter_setter('@help', text)
      end

=begin rdoc
Attribute for determining command name (based on filename).
=end
      def self.command_name(text=nil)
        getter_setter('@command_name', text)
      end

=begin rdoc
Attribute for disabling plugins (this speeds up loading of command).
=end
      def self.disable_plugins
        getter_setter('@plugins_required', false)
      end

=begin rdoc
Attribute for disabling pipeline -- this prevents Pipeline state object from
being read from STDIN or written to STDOUT. Implies end_pipeline.
=end
      def self.disable_pipeline
        getter_setter('@pipeline_supported', false)
        self.end_pipeline
      end

=begin rdoc
Attribute for forcing this command to end a Pipeline. This prevents the 
Pipeline state object from being written to STDOUT.
This should be used in commands that are expected to write data to STDOUT,
thus ending the Pipeline.
=end
      def self.end_pipeline
        getter_setter('@continue_pipeline', false)
      end

=begin rdoc
Returns true if the Command requires plugins.

Note: All Commands require plugins unless the disable_plugins directive is used.
=end
      def self.requires_plugins?
        getter_setter('@plugins_required')
      end

=begin rdoc
Helper method to define attributes.
=end
      def self.getter_setter(name, val=nil)
        val != nil ? instance_variable_set(name, val) : 
                     instance_variable_get(name)
      end

=begin rdoc
Return names of loaded commands, sorted alphabetically
=end
      def self.commands
        @command_names.sort
      end

      #----------------------------------------------------------------------
      # utility routines
=begin rdoc
Return an integer for a string argument in either hex (0[xX][[:xdigit:]]+) or
decimal ([[:digit:]]+) format.
=end
      def self.address_argument(addr)
        (addr =~ /^0?[xX][[:xdigit:]]+$/) ? addr.hex : addr.to_i
      end
    end

=begin rdoc
An error produced by a command. The bgo command line utility will print
these to stderr unstead of a stack trace. Use this for standard error messages,
e.g. invalid or missing argument to command.
=end

    class CommandError < ArgumentError
    end

=begin rdoc
The specified command was not found
=end
    class CommandNotFoundError < StandardError
    end
  end
end
