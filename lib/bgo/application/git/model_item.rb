#!/usr/bin/env ruby
# :title: Bgo::Git::ModelItem
=begin rdoc
Git-backed ModelItem support

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/git/repo'

module Bgo
  module Git

=begin rdoc
Exception raised when a repo-backed object does not exist
=end
    class ObjectNotFound < NameError; end
=begin rdoc
Exception raised when the directory for a repo-backed object cannot be
created because a file with the same name already exists.
=end
    class ModelItemConflict < RuntimeError; end

# =============================================================================
=begin rdoc
A Git::ModelItem class.
BGO Git-backed Data Model items must extend this module.
=end
    module ModelItemClass
      FILE_JSON = 'json'

=begin rdoc
Ident formatted as a String.
=end
      def ident_str(ident)
        ident.to_s
      end

=begin rdoc
Load JSON file containing Git::ModelItem data into Hash. Returns an empty
Hash if the file does not exist.
Note: This must be called from with a Repo#chdir.
=end
      def load_json(base_dir, fname=FILE_JSON)
        path = File.join(base_dir, fname)
        raise ObjectNotFound.new(path) if ! (File.exist? path)
        buf = File.read( path )
        JSON.parse( buf, :symbolize_names => true )
      end

=begin rdoc
Remove ModelItem from Repository and filesystem.
=end
      def delete(repo, base_dir, ident)
        repo.remove File.join(base_dir, ident)
      end
    end

# =============================================================================
=begin rdoc
A Git::ModelItem class instance.
All BGO Git-backed Data Model items must include this module.
=end
    module ModelItemObject
      FILE_JSON = 'json'

=begin rdoc
Path to this object in the repository. Normally this is set by the create()
or load() method.
=end
      attr_accessor :repo_path

      def gititem_init_parent(obj)
        @parent_git = obj
      end

=begin rdoc
Return repo path to child.
This just appends 'child_name' to @repo_path.
=end
      def child_repo_path(child_name)
        File.join(repo_path, child_name)
      end

=begin rdoc
Git::Repo object which manages this Git::ModelItem object. This recurses up
the object tree until @cached repo is defined, or the top-level object (Project)
is reached.
=end
      def repo
        @cached_repo ||= (@parent_git ? @parent_git.repo : nil)
      end

=begin rdoc
Ident formatted as a String.
=end
      def ident_str
        ident.to_s
      end

=begin rdoc
Create files in base_dir to represent ModelItem object, then add items to 
Repo. This is called during ModelItem object creation, when the ModelItem
object has been instantiated but has not been returned to its parent for
initialization (hence gititem_init_parent has not yet been called).
=end

      def create_in_repo(repo, base_dir)
        repo.chdir do
          # do not create if already exists!
          next if (File.exist? base_dir) && (File.directory? base_dir)
          create_dir_for_modelitem(base_dir)

          # create main JSON file in repo
          fname = File.join(base_dir, FILE_JSON)
          buf = self.to_core_hash.to_json + "\n"
          File.open(fname, 'w') { |f| f.write buf }
          repo.add fname
        end
        self
      end

=begin rdoc
Create a directory in the repo for a modelitem object at 'path'.
This will raise a ModelItemConflict if the directory cannot be created due to
a path conflict, or Errno::EACCES if there is a permission error.
Note: this must be called in a Repo#chdir block.
=end
      def create_dir_for_modelitem(path)
        if (File.exist? path) && (! File.directory? path)
          raise ModelItemConflict.new("'#{path}' exists and is not a directory")
        else
          Dir.mkdir(path)
        end
      end

=begin rdoc
Write contents to disk at specified path. If the file does not exist, add it
to the git repository.
=end
      def write_repo_file(path, contents)
        git_add = File.exist? path
        File.write(path, contents)
        repo.add(path) if git_add
      end

      # ----------------------------------------------------------------------

=begin rdoc
Update object and commit changes to repo.
This returns a copy of the object so that methods can be chained.
=end
      def save(msg=nil)
        msg ||= 'Bgo object saved.'
        update
        repo.commit_index msg
        self
      end

=begin rdoc
Update object and commit changes to repo.
This returns a copy of the object so that methods can be chained.

Note: This does not write to disk if self#repo is nil (i.e. before
gititem_init_parent is called).
=end
      def update(&block)
        yield self if block_given?
        return self if ! repo

        repo.chdir {
          File.write( File.join(repo_path, FILE_JSON),
                      self.to_core_hash.to_json + "\n" )
        } #if self_dirty?
        # NOTE: self_dirty does not get set when tags, comments, or properties
        #       are modified!

        @self_dirty = false

        self
      end

=begin rdoc
Unconditional update.
This just sets the dirty flag and invokes update(). Generally, this is used
during ModelItem creation.
=end
      def update!(&block)
        dirty!
        update(&block)
      end


      # ----------------------------------------------------------------------
      # dirty/clean status
=begin rdoc
Return true if Object or children are dirty.
=end
      def dirty?
        @child_dirty || @self_dirty 
      end

      def self_dirty?
        @self_dirty
      end

      def children_dirty?
        @child_dirty
      end

=begin rdoc
Mark self as dirty, and notify parent that children are dirty.
=end
      def dirty!(from_child=false)
        if from_child
          @child_dirty = true
        else
          @self_dirty = true
        end
        @parent_git.dirty!(true) if @parent_git
        self
      end

=begin rdoc
Convenience function for setting child_dirty. This is generally used when 
deleting children.
=end
      def children_dirty!
        @child_dirty = true
        self
      end

=begin rdoc
Mark self and children as clean.
=end
      def clean!(from_child=false)
        @child_dirty = @self_dirty = false
        self
      end
    end

  end
end
