#!/usr/bin/env ruby
# :title: Bgo::Git::Map
=begin rdoc
BGO Map object in Git-DB.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end  

require 'bgo/map'
require 'bgo/application/git/model_item'
require 'bgo/application/git/address_container'

module Bgo
  module Git

    class Map < Bgo::Map
      extend Git::ModelItemClass
      include Git::ModelItemObject
      extend Git::AddressContainerClass
      include Git::AddressContainerObject

      # ModelItem has its own ident_str which is not compatible with Map
      def self.ident_str(load_addr)
        Bgo::Map::ident_str load_addr
      end

      def ident_str
        Bgo::Map.ident_str start_addr
      end

      def self.create( repo, base_dir, start_addr, img, img_off=0, size=nil,
                       flags=DEFAULT_FLAGS, &block)
        m = self.new start_addr, img, img_off, size, flags
        yield m if block_given?
        m.create_in_repo(repo, base_dir)
      end

      def create_in_repo(repo, base_dir)
        self.repo_path = File.join(base_dir, self.ident_str)
        super repo, repo_path

        create_address_container_in_repo repo, repo_path

        dirty!
        self
      end

      def gititem_init_parent(obj)
        super
        address_container_init_parent
      end

      # ----------------------------------------------------------------------
      def update(&block)
        address_container_update
        super

        clean!
        self
      end

      def self.load(repo, path, proj)
        repo.chdir do
          h = load_json(path).merge address_container_load(repo, path)
          m = self.from_hash h, proj
          m.repo_path = path
          m
        end
      end

      # ----------------------------------------------------------------------
      # Wrappers to dirtify object

      def flags=(lst); dirty!; super; end
      def size=(num); dirty!; super; end
      def offset=(num); dirty!; super; end
      def start_addr=(num); dirty!; super; end
      alias :vma= :start_addr=

    end

  end
end
