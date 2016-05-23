#!/usr/bin/env ruby
# :title: Bgo::Git::Packet
=begin rdoc
BGO Packet object in Git-DB.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end  

require 'bgo/packet'
require 'bgo/arch_info'

require 'bgo/application/git/model_item'
require 'bgo/application/git/target'
require 'bgo/application/git/sectioned_target'

module Bgo
  module Git

    class Packet < Bgo::Packet
      extend Git::ModelItemClass
      include Git::ModelItemObject
      extend Git::TargetClass
      include Git::TargetObject
      include Git::SectionedTargetObject

      def self.create(repo, base_dir, name, path, img, off, size, &block)
        f = self.new name, path, img, off, size
        yield f if block_given?
        f.create_in_repo(repo, base_dir)
      end

      def create_in_repo(repo, base_dir)
        self.repo_path = File.join(base_dir, self.ident)
        super repo, repo_path

        create_sectioned_target_in_repo(repo, repo_path)

        dirty!
        self
      end

      def initialize( pkt_ident, img, img_offset=0, sz=nil )
        initialize_git_sectioned_target
        super
      end

      # ----------------------------------------------------------------------
      def update(&block)
        target_update

        super

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

    end

  end
end
