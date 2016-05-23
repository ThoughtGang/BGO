#!/usr/bin/env ruby
# :title: Bgo::Commands::Comment
=begin rdoc
BGO command to add, remove, or list Comments for ModelItem objects

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'rubygems'
require 'json/ext'

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

module Bgo
  module Commands

=begin rdoc
A command to manipulate BGO data model object Comments
=end
    class CommentCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Manage the Comments of a BGO data model item'
      usage "#{Commands.data_model_usage} [-acr str] OBJPATH TEXT"
      help "Add, remove, and list the Comments of a BGO object.
Category: porcelain

Options:
  -a, --author=str       Attribute comment to the specified author.
  -c, --context=str      Assign comment to provided context [default is general]
  -r, --remove           Remove the specified comments.
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

Examples:
  # Display comments for Process 1001
  bgo comments process/1001 
  # Add a comment with the default author and context to Process 1001
  bgo comments process/1001 'this is a meaningless comment'
  # Add a comment by author 'me' with the default context to Process 1001
  bgo comments -a me process/1001 'updated based on new info'
  # Add a comment for the default author with context 'todo' to Process 1001
  bgo comments -c todo process/1001 'add documentation for this object'
  # Remove comment by 'self' in context 'todo' from Process 1001
  bgo properties -r -a self -c todo process/1001

See also: inspect, properties, tag"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        return false if (! options.path)
        options.author ||= ENV[Bgo::Env::AUTHOR]
        options.author ||= Bgo::Comment::AUTH_UNK

        obj = state.item_at_obj_path options.path
        if (! obj)
          $stderr.puts "Invalid object path '#{options.path}'"
          return false
        end
        
        if (! options.text) and (! options.remove)
          $stdout.puts obj.details_clean(obj.details_comments).join("\n")
          end_pipeline
        else
          options.remove ? \
            obj.comments.remove(options.author, options.context) : \
            obj.set_comment(options.text, options.context, options.author)
          state.project.update
        end

        true
      end

      def self.get_options(args)
        options = OpenStruct.new
        options.path = nil
        options.author = nil
        options.context = nil
        options.text = false
        options.remove = false

        opts = OptionParser.new do |opts|
          opts.on( '-a', '--author name' ) { |s| options.author = s }
          opts.on( '-c', '--context name' ) { |s| options.context = s.to_sym }
          opts.on( '-r', '--remove' ) {options.remove = true}

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        options.path = args.shift
        if args.length > 0
          options.text = args.join(' ')
          args.clear
        end

        return options
      end

    end

  end
end

