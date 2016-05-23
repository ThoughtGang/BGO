#!/usr/bin/env ruby
# :title: Bgo::Git::ImageChangeset
=begin rdoc
BGO ImageChangeset object in Git-DB.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/git/image_revision'

module Bgo
  module Git

=begin rdoc
This is a thin wrapper object that supports lazy-loading of ImageRevision
objects. It does not exist as a standalone ModelItem object.
=end
    class ImageChangeset < Bgo::ImageChangeset

      attr_accessor :parent_gititem

      def initialize(repo, repo_path, base_image, base_vma=0)
        super base_image, base_vma
        @repo = repo
        @repo_path = repo_path
        @revisions = [] # IMPORTANT: Revision 0 must be lazy-loaded
        @init_revisions = false
      end

      def update
        revisions(true).each do |ident|
          next if ! @revisions[ident]
          @revisions[ident].update
        end
      end

      # -----------------------------------------------------------------------

      def revision(ident=nil)
        ident ||= current_revision
        return super(ident) if @revisions[ident]
        obj = ImageRevision.load(@repo, File.join(@repo_path, ident.to_s),
                            base_image)
        add_revision_object obj
      end

      def revisions(ident_only=false, &block)
        return super if @init_revisions
        return to_enum(:revisions, ident_only) if ! block_given?

        @repo.chdir do
          Dir.glob(File.join(@repo_path, '*')).each do |f|
            ident = Integer(File.basename(f))
            yield ident_only ? ident : revision(ident)
          end
        end
        @init_revisions = true 
      end

      def remove_revision(rev)
        rev_path = File.join(@repo_path, rev.to_s)
        File.delete(rev_path) if (File.exist? rev_path)
        super
      end

      def fill_from_hash(h)
        (h[:revisions] || []).each do|rev_h|
          rev = ImageRevision.from_hash rev_h, @base_image
          import_revision(rev)
        end
        h[:revisions] = []
        super
      end

      protected

      def add_revision_object(obj)
        obj.gititem_init_parent parent_gititem
        obj.repo_path = @repo_path
        super
      end

      def new_revision(ident, is_empty=false)
        ImageRevision.new(ident, is_empty)
      end

    end

  end
end
