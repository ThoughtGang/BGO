#!/usr/bin/env ruby
# :title: Bgo::Commands::CreateFile
=begin rdoc
BGO command to create a new TargetFile object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/model_item'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

require 'bgo/file'
require 'bgo/image'

module Bgo
  module Commands

=begin rdoc
A command to create an File in a project or stream.
=end
    class CreateFileCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Create a BGO TargetFile'
      usage "#{Commands.data_model_usage} [-i id] [-os int] [-c str] PATH"
      help "Create a TargetFile object in a Project or stream.
Category: plumbing

This creates a BGO TargetFile object from an on-disk file or from an Image
object in the project or stream. If the -i argument is provided, the specified
Image object is used for the File contents; otherwise, an Image object is
created for the contents of the file at PATH. Note that if the -i argument
is provided, PATH need not refer to an existing file on disk; it is used only
to determine the name and (unique) path of the TargetFile object.

The -o and -s arguments specify the offset into the Image object at which the
TargetFile contents start and the size of the TargetFile contents. This can be 
used to create a TargetFile object for the contents of an archive file 
(e.g. a .tar file).

By default, a TargetFile has a path that is identical to its name (i.e., no
directory is specified). A directory for this path can be specified with the
--local-dir option, or the original path of the file can be used by using the 
--keep-path option. Note that this path is used for identification purposes
only; two TargetFiles with the same name must have different paths.

Options:
  -c, --comment string   Comment for TargetFile object
  -i, --image ident      Image object containing TargetFile
  -o, --offset num       Offset of TargetFile in Image object
  -s, --size num         Size of TargetFile
  -P, --parent ident     Parent (e.g. archive) TargetFile containing TargetFile
  --keep-path            Retain original path of file
  --local-dir string     Set TargetFile path to local-dir + filename
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

Examples:
  # Create TargetFile object from file /tmp/a.out on disk
  bgo file-create '/tmp/a.out'
  # Create TargetFile object for existing Image object
  bgo file-create -i 24ce0f78e5d6172a5c6d50b83d6104aa4144b317 '/lib/libfoo.a'
  # Create child TargetFile object inside existing TargetFile object
  bgo file-create -P '/lib/libfoo.a' -o 1024 -s 100 'bar.o'

See also: file, file-delete, file-edit, image-create"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        options.parent = Commands.file_ident_or_path(state,options.parent_ident)
        options.image = options.image_ident ? 
                         state.image(options.image_ident) : nil

        options.paths.each do |path| 
          options.parent ? create_child_file(options, state, path) : \
                           create_file(options, state, path)
        end
        state.save("File(s) added by cmd FILE CREATE")
        
        true
      end

      def self.create_child_file(options, state, path)
        name = File.basename(path)
        f = options.image ? \
              options.parent.add_discrete_file(name, path, options.image, 
                                               options.offset, options.size) : \
              options.parent.add_file(name, path, options.offset, options.size)
        f.comment = options.comment if options.comment
      end

      def self.create_file(options, state, path)
        img = options.image

        fname = File.basename(path)
        proj_path = options.local_dir ? File.join(options.local_dir, fname) :
                                          fname
        proj_path = path if options.keep_path

        f = img ? state.add_file_for_image(path, img, options.offset, 
                            options.size ) : state.add_file(path, proj_path)
        f.comment = options.comment if options.comment
      end

      def self.get_options(args)
        options = super

        options.comment = nil
        options.image_ident = nil
        options.parent_ident = nil
        options.offset = 0
        options.size = nil
        options.local_dir = nil
        options.keep_path = false
        options.paths = []

        opts = OptionParser.new do |opts|
          opts.on( '-c', '--comment string' ) { |str| options.comment = str }
          opts.on( '-i', '--image ident' ) { |id| options.image_ident = id }
          opts.on( '-P', '--parent ident' ) { |id| options.parent_ident = id }
          opts.on( '-o', '--offset num' ) { |n| options.offset = n }
          opts.on( '-s', '--size num' ) { |n| options.size = n }
          opts.on( '--local-dir string') { |str| options.local_dir = str }
          opts.on( '--keep-path') { options.keep_path = true }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1
        while args.length > 0
          options.paths << args.shift
        end

        return options
      end

    end

  end
end

