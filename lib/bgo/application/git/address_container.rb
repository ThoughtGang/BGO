#!/usr/bin/env ruby
# :title: Bgo::Git::AddressContainer
=begin rdoc
BGO AddressContainer object in Git-DB.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

# NOTE: Addresses are stored in per-revision files in 'revision' dir
#       * revision files are created by ImageChangeset on update
#       * revision files are deleted by ImageChangeset on remove

require 'bgo/application/git/image_changeset'

module Bgo
  module Git

    module AddressContainerClass
      FILE_BLK = 'block'

      def address_container_load(repo, path)
        h = {}
        repo.chdir do
          h[:block] = load_json(path, FILE_BLK)
        end
        h
      end
    end

    module AddressContainerObject

      FILE_BLK = AddressContainerClass::FILE_BLK
      DIR_CS = 'revisions'

      def create_address_container_in_repo(repo, parent_dir)
        repo.chdir do
          Dir.chdir(parent_dir) do
            # Create 'revisions' directory
            Dir.mkdir(DIR_CS) if (! File.exist? DIR_CS)
            # Create initial revision (the Empty changeset)
            # NOTE: changeset is empty at this point
            write_repo_file( File.join(DIR_CS,'0'), 
                             @changeset.revision.to_hash.to_json )
          end
        end
      end

      # NOTE: This cannot be called from child_initialize() method, as the
      #       Git Modelitem info has not been set.
      def address_container_init_parent
        @changeset = ImageChangeset.new(repo, child_repo_path(DIR_CS), 
                                        base_image, start_addr)
        @changeset.parent_modelitem = self
        @changeset.parent_gititem = self
      end

      def address_container_update
        @changeset.update
        repo.chdir do
          write_repo_file( File.join(repo_path, FILE_BLK),
                           @block.to_hash.to_json + "\n" )
        end
      end

      # ----------------------------------------------------------------------
      # DELEGATORS to ImageChangeset
      # (cannot use Forwardable for these)

      def revision(rev=nil); @changeset.revision(rev=nil); end
      def revision=(val); @changeset.revision=(val); end
      def revisions(ident_only=false, &block)
        @changeset.revisions(ident_only=false, &block)
      end
      def add_revision; @changeset.add_revision; end
      def remove_revision(rev); @changeset.remove_revision(rev); end
      def clear_revision(rev); @changeset.clear_revision(rev); end
      def import_revision(rev); @changeset.import_revision(rev); end
      def current_revision; @changeset.current_revision; end
      def address(vma, rev=nil); @changeset.address(vma, rev=nil); end
      def remove_address(vma, rev=nil)
        @changeset.remove_address(vma, rev=nil)
      end
      def image(rev=nil); @changeset.image(rev=nil); end
      def patch_bytes(vma, bytes); @changeset.patch_bytes(vma, bytes); end

    end

  end
end
