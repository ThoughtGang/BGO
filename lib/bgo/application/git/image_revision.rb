#!/usr/bin/env ruby
# :title: Bgo::Git::ImageRevision
=begin rdoc
BGO ImageRevision object in Git-DB.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/image_revision'
require 'bgo/application/git/model_item'

module Bgo
  module Git

    class ImageRevision < Bgo::ImageRevision
      extend Git::ModelItemClass
      include Git::ModelItemObject

      def self.load(repo, path, img)
        repo.chdir do
          h = load_json File.dirname(path), File.basename(path)
          self.from_hash h, img 
        end
      end

      def update(&block)
        yield self if block_given?
        return self if ! repo

        repo.chdir {
          write_repo_file( File.join(repo_path, ident.to_s),
                           self.to_hash.to_json + "\n" )
        } #if self_dirty?

        @self_dirty = false

        clean!
        self
      end

      # ----------------------------------------------------------------------
      # Wrappers that dirtify object
      def patch_bytes(vma, bytes); dirty!; super; end

      def clear_changed_bytes; dirty!; super; end

      def add_address(vma, addr); dirty!; super; end

      def remove_address(vma); dirty!; super; end

      def clear_addresses; dirty!; super; end

    end

  end
end
