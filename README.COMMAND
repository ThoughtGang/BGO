			BGO Toolchain commands

The bin/bgo commands are defined by the ruby modules located in the directory 
lib/bgo/application/commands . Additional command directories can be
specified by the user, and Plugin can also define commands.

The bin/bgo commands are designed to operate in one of two modes:

  a) As a toolchain, in which the output of one command is piped to another.
     This serializes the BGO data to and from JSON, which can be inefficient
     with large targets or when chaining many commands.

  b) On a BGO project (which is a wrapper for a Git repository). This
     serializes data to and from a BGO project, and is recommended for
     all non-trivial use of the framework.

Which mode is used depends on whether a project is available (either specified
by the user or inferred from the current working directory) and whether STDIN
and STDIN are TTYs.

The toolchain mode is known as the "pipeline", and support is provided by
  lib/bgo/application/commands/shared/pipeline.rb


----------------------------------------------------------------------
Standard Options

  These are defined in: 
    lib/bgo/application/commands/shared/standard_options.rb
    lib/bgo/application/commands/shared/data_model_options.rb 
    lib/bgo/application/commands/shared/plugin.rb

  -p, --project path     Path to BGO project
  -u, --use-plugin name  Name or canon_name of plugin to use
  --plugin-options str   JSON-encoded Hash of options to send to plugin
  --no-project-detect    Do not attempt to detect BGO project; this is needed
                         if the working directory is in a Git repository
  --, --stdin            Read input from STDIN; do not attempt to detect project
  --no-stdin             Do not read input from STDIN
  --stdout               Force output to be written to STDOUT
  --no-stdout            Do not write output to STDOUT
  --cron                 Combination of --no-stdin and --no-project-detect
  --nop                  Ignored option; this is used to force the previous 
  -v, --verbose          Print verbose messages
  --version              Display BGO version number
  --help                 Display usage statement and options
                         option to not take an (optional) argument

----------------------------------------------------------------------
Environment Variables

  These are defined in lib/bgo/application/env.rb

  BGO_CONFIG - Location of BGO config files. This overrides settings in the 
               default config files. Note that this is a directory, not a file;
               the config files must still be named 'framework.yaml', 
               'plugins.yaml', etc.

  BGO_PROJECT - Path to the BGO Project to operate on. This is equivalent to 
               using the -p argument in a BGO Command. This gets copied to 
               the GIT_DIR environment variable.

  BGO_DISABLE_PROJECT_DETECT - Do not attempt to detect whether the current 
               directory is inside a BGO project. This is will prevent a BGO 
               project from being detected when the current directory is not 
               in a BGO project, but is in a GIT repository.   

  BGO_DISABLE_GIT - Prevent use of Bgo::Git in Commands. This is used for 
               testing, or if grit cannot be installed. The default behavior 
               will fall back on streams of JSON-encoded data.

  BGO_PLUGINS - Paths for BGO plugins. This is a standard UNIX colon-delimited 
               pathspec. These paths will be added to the head of the BGO 
               Plugin path list.

  BGO_PLUGIN_BLACKLIST - List of blacklisted plugins. This is a colon-delimited
               list of Plugin names. The names are matched against 
               Plugin#canon_name. Note that the Plugin canonical name is 
               Plugin#name + '-' + Plugin#version. This must be an exact match 
               for the Plugin to be blacklisted; wildcards are not allowed.

  BGO_PLUGIN_FILE_BLACKLIST - List of blacklisted plugins. This is a standard 
               UNIX colon-delimited pathspec. These paths are matched to plugin
               files (ruby modules) using String#end_with?.

  BGO_PLUGIN_DEBUG - Enable debug messages for Plugin Manager. This will write 
               exceptions raised by plugins to $TG_PLUGIN_DEBUG_STREAM (by 
               default, STDERR).

  BGO_COMMANDS - Paths for BGO commands. This is a standard UNIX colon-delimited
               pathspec. These paths will be added to the head of the BGO 
               Command path list.

  BGO_RUBYLIB - Ruby module path for BGO plugin. This is a standard UNIX 
               colon-delimited pathspec. These paths are added to the head of 
               the Ruby Library path ($:).


  BGO_AUTHOR_NAME - Name of the BGO application user. This is used in comments 
               and in the Git repo config.

  BGO_AUTHOR_EMAIL - Email of the BGO application user. This is used in the Git
               repo config.


----------------------------------------------------------------------
Plumbing

* Object Creation
    address-create
    block-create
    file-create
    image-create-remote - Create an RemoteImage object in a Project or stream
    image-create-virtual - Create a VirtualImage object in a Project or stream
    image-create
    map-create
    process-create
    project-create
    revision-create
    section-create

* Object view/update
    address-edit
    address
    arch-edit - Set/edit ArchInfo details for a ModelItem object
    block
    comment - Add, remove, or list Comments for a ModelItem object
    file-edit
    file
    image-edit
    image
    inspect - Display details of a ModelItem object
    map-edit
    map
    process-edit
    process
    project-edit
    project
    properties - Add, remove, or list Properties for a ModelItem object
    revision-edit
    revision
    section-edit
    section
    tag - Add, remove, or list Tags for a ModelItem object

* Object delete
    file-delete
    address-delete
    image-delete
    map-delete
    process-delete
    revision-delete
    section-delete

* Pipeline Management
    eval - eval() Ruby code on a project or pipeline. NOTE: This will end the
           pipeline, meaning the Ruby code can write to STDOUT.
    pipeline-eval - eval() Ruby code on a Pipeline
    pipeline-history - Print a Pipeline command history to STDOUT
    pipeline-print - Print a JSON Pipeline to STDOUT
    pipeline-tree - Print Pipeline working_data object tree to STDOUT
    plugin-eval - eval() Ruby code on a Pipeline with a specified Plugin loaded


----------------------------------------------------------------------
Porcelain

* Plugin management
    plugin-dirs - List plugin directories
    plugin-help - Display plugin help string
    plugin-info - Display plugin details
    plugin-list - List available plugins
    plugin-specs - List defined plugin specifications

* Interfaces
    decode-insn - Decode one or more assembly language instructions to STDOUT
    disasm-bytes - Disassemble a file or string using a Disassembler plugin
    ident-bytes - Run an Ident plugin on a file or string and write to STDOUT
    load-bytes - Create Maps from a file or string using a Loader plugin
    load-target - Run a load_target plugin on TargetFile objects
    parse-bytes - Parse a file or string using a Loader plugin
    target-disasm - Load and disassemble one or more files or strings. NOTE:
                    This will create a Project and a Process.

* General commands
    echo - Print arguments to STDOUT. Used only for testing.
    help 
    info - List supported architectures and file formats
