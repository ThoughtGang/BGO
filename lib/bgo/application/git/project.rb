#!/usr/bin/env ruby
# :title: Bgo::Git::Project
=begin rdoc
BGO Project object in Git-DB.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'forwardable'

require 'bgo/project'
require 'bgo/version'
require 'bgo/application/git/repo'
require 'bgo/application/git/model_item'

require 'bgo/application/git/image'
require 'bgo/application/git/file'
require 'bgo/application/git/packet'
require 'bgo/application/git/process'

module Bgo
  module Git

=begin
Git-backed Project object.
This exists in the top-level directory of the repo.
=end
    class Project < Bgo::Project
      extend Forwardable
      extend Git::ModelItemClass
      include Git::ModelItemObject

      # Git Config file entries
      BGO_VERSION_CFG='bgo.version'
      BGO_CREATED_CFG='bgo.created'
      # Git Actor for commits forced by BGO
      BGO_ACTOR_NAME = 'Bgo::Git'
      BGO_ACTOR_EMAIL = 'dev@thoughtgang.org'
      BGO_ACTOR = Grit::Actor.new( BGO_ACTOR_NAME, BGO_ACTOR_EMAIL )

      FILE_MAGIC = 'bgo'
      DIR_IMG = 'image'
      DIR_FILE = 'file'
      DIR_PKT = 'packet'
      DIR_PROC = 'process'
      DIR_TAG = 'tag'

      def_delegators :@repo, :config, :top_level, :actor, :set_actor

=begin rdoc
Create a BGO Git-backed Project at path.
The path argument is the full path to the directory that will contain the
Project repo, e.g. "/tmp/my_project.bgo". The directory will be created if
it does not exist.
If a block is given, the Project object will yield to the block, then
saved on block exit. This returns the newly-created Project object.

Example:
  Bgo::Git::Project.create('/tmp/target.bgo', 'target') do |p|
    # ... operations on Project
  end

  p = Bgo::Git::Project.create('/tmp/target_1.bgo, 'target1')
  # ... operations on Project
  p.close
=end
      def self.create(path, name, descr=nil, &block)
        r = Repo.create(path)
        create_in_repo(r, name, descr, &block)
      end

=begin rdoc
Create BGO repository in an existing Git repo.
This can be used to initialize a checkout of a bare repo on a server.
=end
      def self.create_in_repo(r, name, descr=nil, &block)
        initialize_repo r

        p = self.open(r.top_level)
        p.name = name
        p.descr = descr
        yield p if block_given?

        p.save 'Initial project create'
        p
      end

=begin rdoc
Initialize config file and such for project repo.
Note: Git username will be obtained from ENV.
=end
      def self.initialize_repo(r)
        path = r.top_level
        create_ts = Time.now.strftime('%Y-%m-%d %H:%M')
        # FIXME: config gets lost when cloning. This is pointless.
        r.config[BGO_VERSION_CFG] = Bgo::VERSION.to_s
        r.config[BGO_CREATED_CFG] = create_ts

        name = ENV['BGO_AUTHOR_NAME']
        email = ENV['BGO_AUTHOR_EMAIL'] || ''
        r.set_actor(name, email) if name && ! name.empty?

        fname = File.join(path, FILE_JSON)
        h = { :name => nil }
        File.open( fname, 'w') { |f| f.puts h.to_json }
        r.add(fname)
      end

=begin rdoc
Open a Git-backed Bgo Project.
If passed a block, the Project object is yielded to the block. This will
close (and autosave) the Project on block exit.

  Bgo::Git::Project.open('/tmp/test.bgo') do |proj|
    # ... work on project ...
  end
  # project is saved and closed.

Note that closing a project is only used for notifying subscribers and
performing an autosave. It is not dangerous to work on an already-closed
project.
=end
      def self.open(path=nil, &block)
        path = Git::Repo.top_level if (! path) || path.empty?
        raise ArgumentError, 'Path is not in a BGO Project' if not path

        raise ArgumentError, "'#{path}' is not a BGO Project" if \
              (! valid_project? path)

        project = self.load(path)
        return project if not block_given?

        yield project
        project.close(true)
        project
      end

      def self.valid_project?(path)
        File.exist? File.join(path, 'json')
      end

      def self.top_level
        path = Git::Repo.top_level
        valid_project?(path) ? path : nil
      end

      # ----------------------------------------------------------------------
      def initialize(path, name=DEFAULT_NAME, descr=DEFAULT_DESCR)
        @repo_path = path
        @repo = Repo.new(path)
        self.current_author= @repo.current_actor.name

        # initialize in-repo paths and filenames
        @repo.chdir do
          Dir.mkdir(DIR_IMG) if (! File.exist? DIR_IMG)
          Dir.mkdir(DIR_FILE) if (! File.exist? DIR_FILE)
          Dir.mkdir(DIR_PKT) if (! File.exist? DIR_PKT)
          Dir.mkdir(DIR_PROC) if (! File.exist? DIR_PROC)
          Dir.mkdir(DIR_TAG) if (! File.exist? DIR_TAG)
        end

        # mark lazy-loaded objects as not loaded
        @init_images = @init_files = @init_packets = @init_processes = false

        super name, descr

        # NOTE: These will be overwritten by values in JSON file
        @bgo_version = @repo.config[BGO_VERSION_CFG] || Bgo::VERSION.to_s
        @created = @repo.config[BGO_CREATED_CFG] ? 
                   Time.parse(@repo.config[BGO_CREATED_CFG]) : Time.now
      end

      def repo; @repo; end

      def name=(str); dirty!; super; end

      def description=(str); dirty!; super; end
      alias :descr= :description=

      # ----------------------------------------------------------------------

=begin rdoc
This changes both the current_author and the Repository actor.
=end
      def set_author!(actor_name, email='')
        self.current_author = actor_name
        @repo.set_actor(actor_name, email)
      end

      # TODO: changing changes branch?
      # TODO: merge changes from other repo? diff?  merge, branch, etc
      # TODO: repo tags!

      # ----------------------------------------------------------------------
      

=begin rdoc
Iterator for Image objects in project. If block is not provided, an Enumerator
is returned. If ident_only is true, only the Image idents will be yielded.
=end
      def images(ident_only=false, &block)
        return super if @init_images 
        return to_enum(:images, ident_only) if ! block_given?

        repo.chdir do
          Dir.glob(File.join(DIR_IMG, '*')).each do |f|
            ident = File.basename(f)
            yield ident_only ? ident : image(ident)
          end
        end
        @init_images = true
      end

      def image(ident)
        return super(ident) if @images[ident]
        img = Git::Image.load repo, image_path(ident)
        add_image_object img
      end

      def add_image(buf) 
        img = Git::Image.create repo, DIR_IMG, buf
        children_dirty!
        add_image_object img
      end

      def add_virtual_image(fill, size)
        img = Git::VirtualImage.create repo, DIR_IMG, fill, size
        children_dirty!
        add_image_object img
      end

      def add_remote_image(img_path, sz=nil, img_ident=nil)
        img = Git::RemoteImage.create repo, DIR_IMG, img_path, sz, img_ident
        children_dirty!
        add_image_object img
      end

      def remove_image(ident)
        Git::Image.delete repo, DIR_IMG, ident
        children_dirty!
        super
      end

      # ----------------------------------------------------------------------
=begin rdoc
Iterator for File objects in project. If block is not provided, an Enumerator
is returned. If ident_only is true, only the File idents will be yielded.
=end
      def files(ident_only=false, &block)
        return super if @init_files 
        return to_enum(:files, ident_only) if ! block_given?

        repo.chdir do
          Dir.glob(File.join(DIR_FILE, '*')).each do |f|
            ident = File.basename(f)
            yield ident_only ? ident : file(ident)
          end
        end
        @init_files = true
      end
      alias :target_files :files

      def file(ident)
        return super(ident) if @files[ident]
        f = Git::TargetFile.load repo, file_path(ident), self
        add_file_object f
      end
      alias :target_file :file

      def add_file_for_image(path, img, off=0, size=nil)
        f = Git::TargetFile.create repo, DIR_FILE, File.basename(path), path, 
                                   img, off, size
        children_dirty!
        add_file_object f
      end

      def remove_file(ident)
        Git::TargetFile.delete repo, DIR_FILE, ident
        children_dirty!
        super
      end
      alias :remove_target_file :remove_file

      # ----------------------------------------------------------------------
=begin rdoc
Iterator for Packet objects in project. If block is not provided, an Enumerator
is returned. If ident_only is true, only the Packet idents will be yielded.
=end
      def packets(ident_only=false, &block)
        return super if @init_packets 
        return to_enum(:packets, ident_only) if ! block_given?

        repo.chdir do
          Dir.glob(File.join(DIR_PKT, '*')).each do |f|
            ident = File.basename(f)
            yield ident_only ? ident : packet(ident)
          end
        end
        @init_packets = true
      end

      def packet(ident)
        return super(ident) if @packets[ident]
        f = Git::Packet.load repo, packet_path(ident), self
        add_packet_object f
      end

      def remove_packet(ident)
        Git::Packet.delete repo, DIR_PKT, ident
        children_dirty!
        super
      end

      # ----------------------------------------------------------------------
      def processes(ident_only=false, &block)
        return super if @init_processes 
        return to_enum(:processes, ident_only) if ! block_given?

        repo.chdir do
          Dir.glob(File.join(DIR_PROC, '*')).each do |f|
            ident = Integer(File.basename(f))
            yield ident_only ? ident : process(ident)
          end
        end
        @init_processes = true
      end

      def process(ident)
        return super(ident) if @processes[ident]
        begin
          p = Git::Process.load repo, proc_path(Git::Process.ident_str ident), 
                                self
          add_proc_object p
        rescue ObjectNotFound => e
          $stderr.puts "Invalid Process #{ident}" if $DEBUG_GIT
        end
      end

      def add_process(command, fname=nil, arch_info=nil, ident=nil)
        ident = processes(true).max || DEFAULT_PID - 1
        ident = ident.succ
        p = Git::Process.create repo, DIR_PROC, ident, command, fname, arch_info
        children_dirty!
        add_proc_object p
      end

      def remove_process(ident)
        Git::Process.delete repo, DIR_PROC, Git::Process.ident_str(ident)
        children_dirty!
        super
      end

      # ----------------------------------------------------------------------
=begin rdoc
Commit entire repository.
=end
      def save(msg=nil)
        super( msg || 'Bgo project saved.')
      end

=begin rdoc
Automatic save of project.
Invoked on Project#close
=end
      def autosave
        save 'Project automatically saved by BGO'
        true
      end

=begin 
      def save!
      end
=end

=begin rdoc
Perform operations on project, then write it to disk.
Note: this does not commit.
Example:
  proj.update do |p|
    # ... modify project ...
  end
  # project and children are now updated on-disk
=end
      def update(&block)
        yield self if block_given?

        repo.chdir {
          buf = to_core_hash.to_json
          File.open( FILE_JSON, 'w' ) { |f| f.puts buf }
          repo.add FILE_JSON
        } #if self_dirty?

        if children_dirty?
          @images.each { |k, img| img.update }
          @files.each { |k, f| f.update }
          @processes.each { |k, p| p.update }
        end

        # TODO: tag registry

        clean!
        self
      end

=begin
Load Project from JSON file in repository.
Note that 'path' is the path to the root of the repository; the filename is
generated internally.
This returns a Project object.
=end
      def self.load(path)
        p = self.new path
        Dir.chdir(path) do
          # instantiate project from JSON file. rest is lllllazy
          h = load_json '.'   # we want a file in the root of the Project
          p.fill_from_hash h
        end
        p
      end

      protected

      def add_image_object(obj)
        obj.gititem_init_parent self
        super
      end

      def add_file_object(obj)
        obj.gititem_init_parent self
        super
      end

      def add_packet_object(obj)
        obj.gititem_init_parent self
        super
      end

      def add_proc_object(obj)
        obj.gititem_init_parent self
        super
      end


      private
      def image_path(ident); File.join(DIR_IMG, ident); end

      def file_path(ident); File.join(DIR_FILE, ident); end

      def packet_path(ident); File.join(DIR_PKT, ident); end

      def proc_path(ident); File.join(DIR_PROC, ident); end

    end

  end
end

# ============================================================================
# Possible additions:
=begin rdoc
Commit the repo and associate a tag with the commit.
Return value is the commit SHA.
      def tagged_commit( name, msg, actor=@actor )
        sha = commit( msg, actor )

        repo.tag_object(name, sha)
      end
=end

=begin rdoc
Return Grit::Head object for the current branch.
      def branch
        repo.branch
      end
=end

=begin rdoc
Set current branch to branch. If branch does not exist, it will be created.
      def branch=(name)
        repo.set_branch(name)
      end
=end

=begin rdoc
Return list of branches
      def branches()
        repo.branches
      end
=end

=begin rdoc
Add a new branch, associated with specified commit SHA. Does not switch to
branch.
      def create_branch( name=self.repo.next_branch_tag, sha=nil )
        repo.create_branch(name, sha)
      end
=end

=begin rdoc
Merge specified branch with master.
      def merge( name=self.repo.current_branch, actor=nil )
        repo.merge_branch(name, actor)
      end
=end

=begin rdoc
Creates a tagged commit in the repo. If a block is given, a branch is created
and merged via Model#branched_transaction.

Usage:
    project.save( 'Version 1.0' ) do |opts|
      # optionally override default values
      opts[:name] = ''
      opts[:msg] = ''
      opts[:actor] = Grit::Actor.new(name, email)

      # ...add files, etc...
    end

      def save( tag=db.next_branch_tag, actor=db.actor, &block )
        opts = { :name => tag, :msg => tag, :actor => actor }

        if block_given?
          tag = db.clean_tag(tag)
          branched_transaction(tag, &block)
          branch = tag  # set current branch to tag
          merge(tag, actor)
        end

        sha = db.staging.commit(opts[:msg], opts[:actor])
        db.tag_object(opts[:name], sha)
        db.unstage
      end
=end
