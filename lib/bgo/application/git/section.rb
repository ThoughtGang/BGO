#!/usr/bin/env ruby
# :title: Bgo::Git::Section
=begin rdoc
BGO Section object in Git-DB.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end  

require 'bgo/section'
require 'bgo/application/git/model_item'
require 'bgo/application/git/address_container'

module Bgo
  module Git

    class Section < Bgo::Section
      extend Git::ModelItemClass
      include Git::ModelItemObject
      extend Git::AddressContainerClass
      include Git::AddressContainerObject

      def self.create( repo, base_dir, ident, name, img, img_off=0, file_off=0,
                      size=nil, flags=DEFAULT_FLAGS, &block)
        s = self.new ident, name, img, img_off, file_off, size, flags
        yield s if block_given?
        s.create_in_repo(repo, base_dir)
      end

      def create_in_repo(repo, base_dir)
        self.repo_path = File.join(base_dir, self.ident)
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
          s = self.from_hash h, proj
          s.repo_path = path
          s
        end
      end

      # ----------------------------------------------------------------------
      # Wrappers to dirtify object

      def name=(str); dirty!; super; end
      def flags=(lst); dirty!; super; end
      def size=(num); dirty!; super; end
      def file_offset=(num); dirty!; super; end
      alias :offset= :file_offset=

    end

  end
end
