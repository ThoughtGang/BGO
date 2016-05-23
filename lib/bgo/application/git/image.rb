#!/usr/bin/env ruby
#:title: Bgo::Git::Image
=begin rdoc
BGO Image object in Git-DB

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/image'

require 'bgo/application/git/model_item'

module Bgo
  module Git

    class Image < Bgo::Image
      extend Git::ModelItemClass
      include Git::ModelItemObject

      FILE_BIN = 'blob'

=begin rdoc
Create a new Git::Image object in Repo. The object is yielded to the (optional)
block.
Returns the instantiated Git::Image object.
=end
      def self.create(repo, base_dir, contents, &block) 
        img = self.new contents

        yield img if block_given?

        # chicken-and-egg problem here. we need ident to know repo_path, but
        # we do not have ident until Image has been instantiated.
        img.create_in_repo(repo, base_dir)
      end

=begin rdoc
Create a directory for the Git::Image object in the Repo filesystem and 
store its initial state.
This is only called by Git::Image.create.
=end
      def create_in_repo(repo, base_dir)
        self.repo_path = File.join(base_dir, self.ident)

        super repo, repo_path

        # write contents to FILE_BIN -- note this file never changes!
        repo.chdir do
          fname = File.join(repo_path, FILE_BIN)
          File.binwrite(fname, self.contents)
          repo.add fname
        end
        dirty!

        self
      end

      # ----------------------------------------------------------------------

=begin rdoc
Instantiate an Image object from the specified path (a ModelItem directory)
in the Repo. This will instantiate either an Image or a VirtualImage object.
=end
      def self.load(repo, path)
        repo.chdir do
          h = load_json path
          if h[:virtual]
            return Git::VirtualImage.load repo, path, h
          end
          buf = File.binread( File.join(path, FILE_BIN) )
          img = self.new buf 
          img.repo_path = path
          img.fill_from_hash h
        end
      end
    end

    # =======================================================================
    class RemoteImage < Bgo::RemoteImage
      extend Git::ModelItemClass
      include Git::ModelItemObject

      def self.create(repo, base_dir, img_path, sz=nil, img_ident=nil, &block) 
        img = self.new img_path, sz, img_ident

        yield img if block_given?

        img.create_in_repo repo, base_dir
      end

      def create_in_repo(repo, base_dir)
        self.repo_path = File.join(base_dir, self.ident)
        super repo, repo_path
      end

      # ----------------------------------------------------------------------

      def self.load(repo, path, h=nil)
        repo.chdir do
          h ||= load_json path
          img = self.from_hash h
          img.repo_path = path
          img
        end
      end

    end

    # =======================================================================
    class VirtualImage < Bgo::VirtualImage
      extend Git::ModelItemClass
      include Git::ModelItemObject

      def self.create(repo, base_dir, fill, size, &block) 
        img = self.new fill, size

        yield img if block_given?

        img.create_in_repo repo, base_dir
      end

      def create_in_repo(repo, base_dir)
        self.repo_path = File.join(base_dir, self.ident)
        super repo, repo_path
      end

      # ----------------------------------------------------------------------

      def self.load(repo, path, h=nil)
        repo.chdir do
          h ||= load_json path
          img = self.from_hash h
          img.repo_path = path
          img
        end
      end

    end

  end
end
