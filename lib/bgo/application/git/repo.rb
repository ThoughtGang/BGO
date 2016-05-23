#!/usr/bin/env ruby
# :title: Bgo::Git::Repo
=begin rdoc
Git-backed Repo

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/version'

require 'fileutils'

require 'rubygems'
require 'grit'

# TODO: BRANCH: 
#       git.branch({},"branchname") 
#       git.checkout({},"branchname")
#       commit to branch without doing a checkout:
#       index.commit( comment, repo.commits( branch ), nil, nil, branch )
#       index = repo.index
#       index.read_tree( branch )
#       ...index.add( path_to_a_file, file_data )
#       repo.git.native :checkout, {b: true}, 'my_branch'
#       TAG:
#       t = Grit::Tag.create_tag_object(r, 
#       { :name => '', :message => '', :type => '-a' })
#       log = @repo.git.tag( { 'f' => true }, tag_name, commit_sha )
#       DIFF:
#       paths = [];
#       @commit.diffs.each do |diff|
#           paths += [diff.a_path, diff.b_path]
#       end
#       paths.uniq!
#       ATTRIBUTES: http://git-scm.com/docs/gitattributes

module Bgo
  module Git

    # FROM PREVIOUS IMPLEMENTATION:
    #BGO_ACTOR_NAME = 'Bgo::Git'
    #BGO_ACTOR_EMAIL = 'dev@thoughtgang.org'
    #BGO_ACTOR = Grit::Actor.new( BGO_ACTOR_NAME, BGO_ACTOR_EMAIL )
=begin rdoc
Exception raised to abort a commit from within a Repo#stage block.
=end
    class AbortTransaction < RuntimeError; end

    # ====================================================================

=begin rdoc
Bgo::Git Repository object.
This is derived from Grit::Repo.
=end
    class Repo < Grit::Repo

      # ----------------------------------------------------------------------
=begin rdoc
Repo Commit descriptor.
This is used to allow blocks to do things like edit the message or author of
a commit that will be performed upon block exit.
=end
      class CommitInfo
        attr_reader :repo
        attr_accessor :message
        alias :msg :message
        attr_accessor :actor

        # TODO: reset? i.e. reset repo to previous state; undo all changes

        def initialize(repo, msg, act=nil)
          @repo = repo
          @message = msg
          @actor = act
        end

        #TODO: perform() method?  This would encapsulate the commit in a block
      end
      # ----------------------------------------------------------------------

      GIT_DIR = ::File::SEPARATOR + '.git'

      # TODO: manage this on repository.branch!
      CURR_BRANCH_CFG = 'bgo.current_branch'
      DEFAULT_BRANCH='master'
      attr_reader :current_branch

      # TODO: manage this on repository.tag!
      BRANCH_TAG_CFG = 'bgo.last_branch_tag'
      DEFAULT_TAG = '0.0.0'
      attr_reader :last_branch_tag

      attr_reader :current_actor
      alias :actor :current_actor

=begin rdoc
Initialize Git repository in directory 'path'. This is equivalent to
invoking `git init path` on the command line.

If a block is given, pass repo in to the block:

  Bgo::Git::Repo.create('/tmp/test.bgo') do |repo|
    # ... operations on repo ...
  end

Note that a commit is *not* performed on the repo upon block exit.

Exceptions:
  Errno::EACCES (permission denied)
  Runtime error (path exists and is not a directory)
=end
      def self.create(path, &block)
        if (File.exist? path)
          if (! File.directory? path)
            raise "Cannot create Repo: '#{path}' not a directory"
          end
        else
          FileUtils.mkdir_p(path)
        end

        Grit::Repo.init(path)

        # handle broken Grit init
        `git init #{path}` if not File.exist?(path + GIT_DIR)

        r = self.new(path)
        yield r if block_given?
        r
      end

=begin rdoc
Get top level of the Git Repo containing path. By default, the current working
directory is used. `git-rev-parse --git-dir` is used to find the top-level dir.
Returns nil if path is not in a (BGO) Git repo.
=end
      def self.top_level(path=Dir.getwd)
        old_dir = nil

        if path != '.'
          old_dir = Dir.getwd
          dest = (File.directory? path) ? path : File.dirname(path)
          Dir.chdir dest
        end

        dir = `git rev-parse --show-toplevel`.chomp
        Dir.chdir old_dir if old_dir

        (dir == '.git') ? '.' : dir.chomp(GIT_DIR)
      end

      # ----------------------------------------------------------------------
      def initialize(path, bare=false)
        path = '.' if (! path || path.empty?)

        git_dir_path = bare ? path : path + GIT_DIR
        super(git_dir_path, {:is_bare => bare})

        @current_branch = config[CURR_BRANCH_CFG]
        @current_branch ||= DEFAULT_BRANCH.dup
        @last_branch_tag = config[BRANCH_TAG_CFG]
        @last_branch_tag ||= DEFAULT_TAG.dup

        act_name = config['user.name'] || ENV['GIT_AUTHOR_NAME'] ||
                   ENV['GIT_COMMITTER_NAME'] || 'Unknown'
        act_email = config['user.email'] || ENV['GIT_AUTHOR_EMAIL'] ||
                    ENV['GIT_COMMITTER_EMAIL'] || ''
        set_actor act_name, act_email
      end

=begin rdoc
Return top level of Repo
=end
      def top_level
        git.git_dir.chomp(GIT_DIR)
      end

=begin rdoc
Return true if path exists in repo (on fs or in-tree)
    def include?(path)
      path_to_object(path) ? true : false
    end

    alias :exist? :include?
=end

=begin rdoc
Set Grit::Actor for repo.
This will be the default Actor used for all subsequent commits.  This will
also change the actor in the Git config file. To change the default Actor
without writing to the config file, use Repo#currentactor=.
=end
      def set_actor(name, email='')
        @current_actor = Grit::Actor.new( name, email )
        config['user.name'] = name
        config['user.email'] = email
      end

=begin rdoc                                                                     
Change to the Repo#top_level dir, yield to block, then pop the dir stack.
=end
      def exec_in_git_dir(&block)
        Dir.chdir(top_level, &block)
      end

=begin rdoc
Return a CommitInfo object. Note that current_actor is used for the actor
if one is not specified.
=end
      def commit_info(msg=nil, actor=nil)
        CommitInfo.new(self, msg || 'No message', actor || current_actor)
      end

      # ----------------------------------------------------------------------
=begin rdoc
Perform operations on Repo.
This uses the current (staging) index.
A commit will be performed on the index upon block exit unless the
Git::AbortTransaction exception is raised.

  repo.stage do |idx, cinfo|
    # ... operations in index ...
    cinfo.message = 'Changes made'
  end

Without a block, this just performs a commit.
=end
      def stage(msg=nil, branch='master', actor=nil, &block)
        branch ||= current_branch

        cinfo = commit_info(msg, actor)
        prev = commits(branch, 1).first
        t = prev ? prev.tree : nil
        idx = index 
        idx.read_tree(t.id) if t

        begin
          yield(idx, cinfo) if block_given?
          idx.commit(cinfo.message, [prev], cinfo.actor, t, branch)
        rescue AbortTransaction
          nil
        end
      end

=begin rdoc
Change to the root directory of the repo and execute block.
=end
      def chdir(&block)
        Dir.chdir(top_level, &block)
      end

=begin rdoc
Add path to the repository.
=end
      def add(path)
        chdir { super }
      end

=begin rdoc
Remove path from the repository and the filesystem. The path is deleted 
recursively.
=end
      def remove(path)
        obj = self
        chdir do
          super 
          obj.git.rm({}, '-f', '-r', path)
        end
      end

      private
# FROM PREVIOUS IMPLEMENTATION:
=begin rdoc
Fetch an object from the repo based on its path.
The tree Repo#current_branch will be used.

The object returned will be a Grit::Blob or a Grit::Tree.
      def path_to_object(path)
        treeish = @current_branch
        tree = self.tree(treeish, [path])
        return tree.blobs.first if tree && (not tree.blobs.empty?)
        return tree.trees.first if tree && (not tree.trees.empty?)
        nil
      end
=end
    end

  end
end
