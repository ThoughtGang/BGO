#!/usr/bin/env ruby
# :title: Bgo::Git::TargetFile
=begin rdoc
BGO TargetFile object in Git-DB.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end  

require 'bgo/file'
require 'bgo/arch_info'

require 'bgo/application/git/model_item'
require 'bgo/application/git/target'
require 'bgo/application/git/sectioned_target'

# TODO: serialization: child blocks should be in own file
#                      symtab should be in own file
#                      references should be in own file
module Bgo
  module Git

    class TargetFile < Bgo::TargetFile
      extend Git::ModelItemClass
      include Git::ModelItemObject
      extend Git::TargetClass
      include Git::TargetObject
      include Git::SectionedTargetObject

      DIR_FILE = 'file'

      def self.create(repo, base_dir, name, path, img, off, size, &block)
        f = self.new name, path, img, off, size
        yield f if block_given?
        f.create_in_repo(repo, base_dir)
      end

      def create_in_repo(repo, base_dir)
        self.repo_path = File.join(base_dir, self.ident)
        super repo, repo_path

        repo.chdir { create_dir_for_modelitem(File.join(repo_path, DIR_FILE)) }
        create_sectioned_target_in_repo(repo, repo_path)

        dirty!
        self
      end

      def initialize( name, path, img, img_offset=0, sz=nil )
        @init_files = false
        initialize_git_sectioned_target
        super
      end

      # ----------------------------------------------------------------------
      def update(&block)
        # NOTE: currently target does not track dirty
        # TODO: make blocks, etc be modelitem children?
        target_update # if self.dirty?

        super

        @child_files.each { |k, f| f.update } if children_dirty?

        update_sectioned_target(&block)

        clean!
        self
      end

      # note: need to pass project in order to instantiate image
      def self.load(repo, path, proj)
        repo.chdir do
          h = load_json(path).merge target_load(repo, path)
          f = self.from_hash h, proj
          f.repo_path = path
          f
        end
      end

      # ----------------------------------------------------------------------
      # FIXME : This needs to support child files!
      def files(ident_only=false, &block)
        return super if @init_files
        return to_enum(:files, ident_only) if ! block_given?

        repo.chdir do
          Dir.glob(child_repo_path(File.join(DIR_FILE, '*'))).each do |f|
            ident = File.basename(f)
            yield ident_only ? ident : file(ident)
          end
        end
        @init_files = true
      end

      def file(ident)
        return super(ident) if @child_files[ident]
        f = Git::TargetFile.load repo, file_path(ident), root
        # FIXME : this does not recurse to find child file idents!
        # if ! f
        # @child_files.each { |id, f| file ||= f.file(id)
        # end
        add_file_object f
      end

      def add_discrete_file(name, path, img, offset=0, size=nil)
        f = Git::TargetFile.create repo, child_repo_path(DIR_FILE), 
                                   name, path, img, off, size
        children_dirty!
        add_file_object f
      end

      def remove_file(ident)
        # FIXME : this does not recurse to remove child file idents!
        #if @child_files.include? ident
        Git::TargetFile.delete repo, child_repo_path(DIR_FILE), ident
        #else
        #@child_files.each { |id, f| rv ||= g.remove_file ident }
        #end
        children_dirty!
        super
      end

      # ----------------------------------------------------------------------
      protected

      def add_file_object(obj)
        obj.gititem_init_parent self
        super
      end

      def file_path(ident); child_repo_path(File.join(DIR_FILE, ident)); end

    end

  end
end
