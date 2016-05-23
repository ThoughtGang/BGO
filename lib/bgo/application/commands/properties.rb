#!/usr/bin/env ruby
# :title: Bgo::Commands::Properties
=begin rdoc
BGO command to add, remove, or list Properties for ModelItem objects

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
A command to manipulate BGO data model object Properties
=end
    class PropertiesCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      summary 'Manage the Properties of a BGO data model item'
      usage "#{Commands.data_model_usage} [-r] OBJPATH [NAME[=VALUE]] [...]"
      help "Add, remove, and list the Properties of a BGO object.
Category: porcelain

Properties are set with the syntax NAME=VALUE, where NAME is a String (to be
converted to a Symbol), and VALUE is a String, a number (integer or floating
point, in any supported base), or a JSON-encoded value. Conversion is
performed by invoking Integer(VALUE), then Float(VALUE), and finally defaulting
to treating the value as a string. Note that a JSON-encoded value will always
be interpreted as a String unless the -j flag is used.

Options:
  -j, --json             Values are encoded in JSON
  -r, --remove           Remove the specified properties.
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}

Examples:
  # Display properties for Process 1001
  bgo properties process/1001 
  # Add a String, Integer, and Float property to to Process 1001
  bgo properties process/1001 version=1.0.1-test num_attempts=3 ratio=1.001
  # Add Integer properties to Process 1001 in hex and octal
  bgo properties process/1001 mac=0xaabbccddeeff perms=0700
  # Add a Hash property 'children' to Process 1001
  bgo properties -j process/1001 children='{\"a\":[1,2,3],\"b\" :[3,4,5]}'
  # Add an Array property 'tokens' to Process 1001
  bgo properties -j process/1001 tokens='[\"a\", \"b\", \"c\"]'
  # Remove property 'needs_cflow_analysis' from Process 1001
  bgo properties -r process/1001 needs_cflow_analysis

See also: comment, inspect, tag"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)
        return false if (! options.path)

        obj = state.item_at_obj_path options.path
        if (! obj)
          $stderr.puts "Invalid object path '#{options.path}'"
          return false
        end
        
        if options.properties.empty?
          $stdout.puts obj.details_clean(obj.details_properties).join("\n")
          end_pipeline
        else
          options.properties.each do |p|
            options.remove ? obj.properties.delete(p.to_sym) : \
                             add_property(obj, p, options)
          end
          state.project.update
        end

        true
      end

      def self.add_property(obj, p, options)
        name, *rest = p.split('=')
        val_str = rest.join
        val = options.json ? JSON.parse(val_str) : decode_value(val_str)
        obj.properties[name.to_sym] = val
      end

      def self.decode_value(val)
        obj = Integer(val) rescue nil
        obj ||= Float(val) rescue nil
        obj || val.to_s
      end

      def self.get_options(args)
        options = OpenStruct.new
        options.path = nil
        options.properties = []
        options.json = false
        options.remove = false

        opts = OptionParser.new do |opts|
          opts.on( '-j', '--json' ) {options.json = true}
          opts.on( '-r', '--remove' ) {options.remove = true}

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        options.path = args.shift
        while args.length > 0
          options.properties << args.shift
        end

        return options
      end

    end

  end
end

