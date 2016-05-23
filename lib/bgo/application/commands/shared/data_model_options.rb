#!/usr/bin/env ruby
=begin rdoc
Standard options parsing methods for BGO commands.

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/env'

require 'bgo/project'

require 'optparse'
require 'ostruct'

module Bgo
  module Commands

=begin rdoc
Add data model options to the OptionsParser 'opts'. Fill 'options' structure
with defaults for these settings.

The standard data model options are:
  -p project OR BGO_PROJECT -- otherwise JSON and stdin or stdout. also if 
     . is a project.
=end
    def self.data_model_options(options, opts)
      options.project_detect ||= true   # detect project from .
      options.project_path ||= nil      # detected or specified Git project
      options.project ||= nil

      opts.on( '-p', '--project string' ) { |p| options.project_path = p }
      opts.on( '--no-project-detect' ) { options.project_detect = false }
    end

=begin rdoc
Return the usage string for standard data model options
=end
    def self.data_model_usage; "[-p name]"; end

=begin rdoc
Return the help string for standard data model options
=end
    def self.data_model_options_help
"Standard BGO data model options:
  -p, --project path      Set BGO project to 'path' instead
  --no-project-detect     Do not check if . is a valid BGO project dir"
    end

    def self.data_model_help
"  The -p option is used to specify a Git-DS project to display or modify. If
  this option is not provided, the BGO_PROJECT environment variable will be
  used. A final check is made to determine if the working directory is in a 
  valid Git-DS project (this can be disabled with --no-project-detect). If no
  project is found, JSON-encoded data is read from STDIN and written to STDOUT.

  Note that if a project is specified with -p, STDIN and STDOUT will not be 
  used to read input and output data. To override this, use the --stdin and 
  --stdout options. These are useful for importing data into, or exporting data 
  from, a Git-DS project.

Environment Variables:
  BGO_DISABLE_PROJECT_DETECT  Disable detection of project (from .) if present
  BGO_DISABLE_GIT_GS          Disable Git-DS entirely if present
  BGO PROJECT                 Path to a Git-DS repo containing BGO Project"
    end

=begin rdoc
Add a BGO ModelItem to a parent object or collection. This detects whether the
receiver is a suitable ModelItem parent, a Hash, or an Array.

The receiever (obj argument) can be one of the following:
  * An object supporting the method specified in the method_key argument, which
    takes a ModelItem object as its argument
  * A Hash containing an element specified by the hash_key argument, whose value
    is an Array of ModelItem objects. This Array element will be created if
    it is not present in the Hash
  * An Array of ModelItem objects (or any object responding to :<<)
=end
    def self.modelitem_add(obj, method_key, hash_key, item)
      if obj.respond_to? method_key   # Add item to parent via add method
        obj.send(method_key, item)
      elsif obj.kind_of? Hash         # Add item to Hash under hash_key
        obj[hash_key] ||= []
        obj[hash_key] << item
      elsif obj.respond_to? :<<       # Append item to array
        obj << item
      else
        $stderr.puts "Cannot add Modelitem to #{obj.class} (#{obj.inspect})"
      end
    end

=begin rdoc
This method is used to enumerate BGO ModelItem objects in input data. It
behaves as Enumerator#select, returning an Enumerator over ModelItem objects 
of the specified type (by default: Bgo::ModelItemObject).

The input can be one of the following:
  * An object supporting the method specified in the key argument, which 
    returns an Array or Hash of ModelItem objects
  * A Hash containing an element specified by the key argument, whose value
    is an Array or Hash of ModelItem objects.
  * A Hash of ModelItem objects
  * An Array of ModelItem objects
  * A ModelItem Object

If key argument is nil, the first two input types do not be apply.

If the cls argument is set, objects not matching that type (which need not
be a Bgo::ModelItemObject) will be ignored. Note that kind_of? is used for 
matching the type specified in the cls argument.
=end
    def self.modelitem_enum(data, key=nil, cls=Bgo::ModelItemObject)
      it = [data].each                           # Single ModelItem
      if (key && (data.respond_to? key))      # Object with :key method
        coll = data.send(key)
        it = (coll.respond_to? :values) ? coll.values.each : coll.each
      elsif data.kind_of? Hash                # Hash of ModelItems or w/ :key
        coll = ((key && data[:key]) || data)
        it = (coll.respond_to? :values) ? coll.values.each : coll.each
      elsif data.kind_of? Array               # Array of ModelItems
        it = data.flatten.each
      end
      it.select { |x| x.kind_of? cls }
    end

=begin rdoc
A convenience function for passing a block to modelitem_enum().each .
=end
    def self.each_modelitem(data, key=nil, cls=Bgo::ModelItemObject, &block)
      modelitem_enum(data, key, cls).each(&block)
    end

=begin rdoc
A convenience function for passing a block to modelitem_enum().select .
=end
    def self.select_modelitem(data, key=nil, cls=Bgo::ModelItemObject, &block)
      modelitem_enum(data, key, cls).select(&block)
    end

  end
end
