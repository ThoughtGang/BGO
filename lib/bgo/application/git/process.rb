#!/usr/bin/env ruby
# :title: Bgo::Git::Process
=begin rdoc
BGO Process object in Git-DB.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end  

require 'bgo/process'

require 'bgo/application/git/model_item'
require 'bgo/application/git/target'
require 'bgo/application/git/map'

module Bgo
  module Git

    class Process < Bgo::Process
      extend Git::ModelItemClass
      include Git::ModelItemObject
      extend Git::TargetClass
      include Git::TargetObject

      DIR_MAP = 'map'

      def self.create(repo, base_dir, ident, cmd, fname, arch_info, &block)
        p = self.new ident, cmd, fname, arch_info
        yield p if block_given?
        p.create_in_repo(repo, base_dir)
      end

      def create_in_repo(repo, base_dir)
        self.repo_path = File.join(base_dir, ident_str)
        super repo, repo_path

        repo.chdir do
          # create subdirectories for object children
          create_dir_for_modelitem(File.join(repo_path, DIR_MAP))
        end

        dirty!
        self
      end

      def initialize( ident, command, filename=nil, arch_info=nil ) 
        @init_maps = false
        super
      end

      # ----------------------------------------------------------------------
      def update(&block)
        # NOTE: see comments in Git::File#update
        target_update # if self.dirty?

        super

        if children_dirty?
          @maps.each { |k, m| m.update }
        end

        clean!
        self
      end

      def self.load(repo, path, proj)
        repo.chdir do
          h = load_json(path).merge target_load(repo, path)
          p = self.from_hash h, proj
          p.repo_path = path
          p
        end
      end

      # ----------------------------------------------------------------------
      def command=(str); dirty!; super; end

      def filename=(str); dirty!; super; end

      def arch_info=(ai); dirty!; super; end

      # ----------------------------------------------------------------------
      def maps(ident_only=false, &block)
        return super if @init_maps
        return to_enum(:maps, ident_only) if ! block_given?

        repo.chdir do
          Dir.glob(child_repo_path(File.join(DIR_MAP, '*'))).each do |f|
            ident = Integer(File.basename(f))
            yield ident_only ? ident : map(ident)
          end
        end
        @init_maps = true
      end
      alias :address_space :maps

      def map(load_address)
        return super(load_address) if @maps[load_address]
        m = Git::Map.load repo, map_path(load_address), root
        add_map_object m
      end

      def add_map(image, load_address, offset=0, sz=nil, flags=nil,
                arch_info=nil)
        sz ||= image.size
        check_map_overlap(load_address, sz)
        m = Git::Map.create repo, child_repo_path(DIR_MAP), load_address, 
                            image, offset, sz, flags
        m.arch_info = arch_info if arch_info
        children_dirty!
        add_map_object m
      end

      def remove_map(vma)
        Git::Map.delete repo, child_repo_path(DIR_MAP), ident_str
        children_dirty!
        super
      end

      def add_virtual_image(fill, sz)
        # FIXME?
        super
      end

      def rebase_map(old_vma, new_vma)
        # FIXME! need to move and update Git::Map 
        super
      end

      # ----------------------------------------------------------------------
      protected

      def add_map_object(obj)
        obj.gititem_init_parent self
        super
      end

      def map_path(load_addr)
        child_repo_path(File.join(DIR_MAP, Bgo::Map.ident_str(load_addr)))
      end

    end
  end
end
