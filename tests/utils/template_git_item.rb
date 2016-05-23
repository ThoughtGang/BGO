require 'bgo/application/git/model_item'

module Bgo
  module Git

    class PARENT < Bgo::PARENT
      extend Git::ModelItemClass
      include Git::ModelItemObject

      DIR_child = ''
      FILE_child = ''

      def self.create(repo, base_dir, args, &block)
        c = self.new args
        yield c if block_given?
        c.create_in_repo(repo, base_dir)
      end

      def create_in_repo(repo, base_dir)
        self.repo_path = File.join(base_dir, self.ident)
        super repo, repo_path

        repo.chdir do
          # create subdirectories for object children
        #  create_dir_for_modelitem(File.join(repo_path, DIR_child))
        end

        dirty!
        self
      end

      #def initialize
      #  @init_children = false
      #  super
      #end

      # ----------------------------------------------------------------------
      def update(&block)
        super

        if children_dirty?
          #@CHILDREN.each { |k, v| v.update }
        end

        clean!
        self
      end

      def self.load(repo, path)
        repo.chdir do
          h = load_json path
          #h.merge(target_load repo, path)
          f = self.from_hash h
          f.repo_path = path
          f
        end
      end

      # ----------------------------------------------------------------------
      # TODO: dirty accessors

      # ----------------------------------------------------------------------
      # children

      def CHILDREN(ident_only=false, &block)
        return super if @init_CHILDREN
        return to_enum(:CHILDREN) if ! block_given?

        repo.chdir do
          Dir.glob(child_repo_path(File.join(DIR_child, '*'))).each do |f|
            ident = File.basename(f)
            yield ident_only ? ident : CHILD(ident)
          end
        end
        @init_CHILDREN = true
      end

      def CHILD(ident)
        return super(ident) if @CHILDREN[ident]
        c = Git::child.load repo, CHILD_path(ident)
        add_CHILD_object c
      end

      def add_CHILD(args)
        obj = Git::child.create repo, child_repo_path(DIR_child), args
        children_dirty!
        add_CHILD_object obj
      end

      def remove_CHILD(ident)
        Git::child.delete repo, child_repo_path(DIR_child), ident
        children_dirty!
        super
      end

      protected

      def add_CHILD_object(obj)
        obj.gititem_init_parent self
        super
      end

      def CHILD_path(ident); child_repo_path(File.join(DIR_FILE, ident)); end

    end

  end
end
