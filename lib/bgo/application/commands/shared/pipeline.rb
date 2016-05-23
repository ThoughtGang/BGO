#!/usr/bin/env ruby
# :title: Bgo::Commands::Pipeline
=begin rdoc
Utility class for tying Toolchain commands together in a pipeline.

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo'   # auto-load BGO datamodel classes as-needed
require 'bgo/application/env'
require 'bgo/util/json'

require 'bgo/project'

module Bgo
  module Commands  

=begin rdoc
State of BGO toolchain. This is passed between toolchain commands. 

Note that this is used in ALL commands, even trivial one like echo, in order 
to ensure that they can be chained together via pipes. If a command is run
standalone (i.e. no data is read from STDIN or written to STDOUT), a Pipeline
object is *still* created in order to ease the
=end
    class Pipeline

      extend JsonClass
      include JsonObject

      # TODO: wrap image file process etc to check project then WorkingData

=begin rdoc
Mapping of Hash keys to ModelItem classes.
Note: All top-level classes (Targets and Target dependencies) should be listed.
      Objects in nested Hashes will be handled during parent deserialization.
=end
      MODELITEM_CLASS = {
        Bgo::Project.path_elem.to_sym => Bgo::Project,
        Bgo::Image.path_elem.to_sym => Bgo::Image,
        #Bgo::Buffer.path_elem.to_sym => Bgo::Buffer,
        Bgo::TargetFile.path_elem.to_sym => Bgo::TargetFile,
        Bgo::Process.path_elem.to_sym => Bgo::Process
      }

=begin rdoc
ModelItem classes that never have siblings -- i.e. these are never contained
in a Hash.
=end
      # FIXME : this should be instantiated into state.project
      MODELITEM_SINGLE = [ Bgo::Project ]

      attr_reader :command_history
      attr_reader :working_data
      attr_accessor :project_path
      # TODO: non-persistent use_stdin/stdout options that caller can override

      def initialize(wdata = nil, cmd_hist=nil)
        @working_data = wdata || WorkingData.new
        @command_history = cmd_hist || []
        @project_path = nil
      end

=begin rdoc
Instantiate a new Pipeline for Command 'cmd'. This is generally performed by
reading from STDIN, but this can be managed by options.
=end
      def self.factory(cmd, options)
        state = (self.present? options) ? self.from_stdin : self.new
        state.command_history << cmd 
        state.determine_project_path(options)
        state.instantiate_project
        state
      end

      def self.from_previous_state(cmd, state)
      end

      # ----------------------------------------------------------------------
      # Pipeline interface

=begin rdoc
Return true is Pipeline is present on STDIN. This is basically a TTY check.
=end
      def self.present?(options)
        options.stdin || (! $stdin.tty?)
      end

=begin rdoc
Instantiate Pipeline from JSON object read on STDIN (actually ARGF).
=end
      def self.from_stdin
        obj = self.from_json(ARGF.read)
        return obj if obj.kind_of? self

        if obj.kind_of? Hash
          self.from_hash obj
        else
          $stderr.puts "Invalid input object type #{obj.class} #{obj.inspect}"
          self.new
        end
        #state
      end

=begin rdoc
Return true if project_path is set.
=end
      def project_path?
        @project_path && (! @project_path.empty?)
      end

=begin rdoc
Detect project path based on options.
Note: This will overwrite existing (STDIN) project path with the one in options
=end
      def determine_project_path(options)
        @project_path = options.project_path if options.project_path
        @project_path ||= ENV[Env::PROJECT] if (Env.set? Env::PROJECT)

        if options.project_detect && (! ENV.include? Env::NO_PROJECT_DETECT) &&
           (! ENV.include? Env::NO_GIT)
          require 'bgo/application/git/project'
          @project_path ||= Bgo::Git::Project.top_level
        end
      end

=begin rdoc
Instantiate a project object.
Note : this chooses project_path over working_data[:project]
=end
      def instantiate_project
        if (project_path?) && (! ENV.include? Env::NO_GIT)
          require 'bgo/application/git/project'
          @project = Bgo::Git::Project.open project_path
        end
        @project ||= @working_data[:project]
        # Set current user from ENV variable, if present
        @project.current_user = ENV[Env::AUTHOR] if @project and  \
                                                    ENV.include? Env::AUTHOR
      end

=begin rdoc
Return true if Pipeline object should be serialized to STDOUT.
=end
      def required?(options)
        options.stdout || (! $stdout.tty?)
      end

=begin rdoc
Serialize Pipeline object to STDOUT.
=end
      def to_stdout
        $stdout.puts self.to_json
      end

      # ----------------------------------------------------------------------
      # Project/Datastore API
      # TODO: address, map, section?

      def project
        @project || working_data[:project]
      end

      def project=(proj)
        @project = proj
      end

=begin rdoc
Instantiate an Image object from Project or WorkingData Hash. The 'ident'
argument can be either a complete Image ident, or enough of the start of an
Image ident to identify it uniquely in the Pipeline state.
=end
      def image(ident)
        obj = (@project || @working_data).image ident
        obj || images.select { |i| i.ident.start_with? ident }.first
      end

      def images
        (@project || @working_data).images
      end

      def add_image(buf)
        (@project || @working_data).add_image buf
      end

      def add_virtual_image(fill, size)
        (@project || @working_data).add_virtual_image fill, size
      end

      def add_remote_image(path, size=nil, ident=nil)
        (@project || @working_data).add_remote_image path, size, ident
      end

      def remove_image(ident)
        img = image(ident)
        (@project || @working_data).remove_image(img.ident) if img
      end

=begin rdoc
Instantiate a TargetFile object from Project or WorkingData Hash. The 'ident'
argument can be the ident of a File, or a child of a File.
=end
      def file(ident)
        obj = (@project || @working_data).file ident
        obj || files.map { |f| f.file(ident) }.select { |f| f }.first
      end

=begin rdoc
Instantiate a TargetFile object based on its path. Note that this does not
check children of File objects, which generally have the same path as their 
parent.
=end
      def file_by_path(path)
        files.select { |f| f.full_path == path }.first
      end

=begin rdoc
Instantiate a TargetFile object from Project or WorkingData Hash. The 'str'
argument can be either an ident or a path. If file(str) does not return a
match, file_by_path(str) will be invoked.
=end
      def file_find(str)
        file(str) || file_by_path(str)
      end

      def files
        (@project || @working_data).files
      end

      def add_file(path, proj_path='')
        (@project || @working_data).add_file(path, proj_path)
      end

      def add_file_for_image(path, img, off=0, size=nil)
        (@project || @working_data).add_file_for_image(path, img, off, size)
      end

      def remove_file(ident)
        f = file(ident)
        (@project || @working_data).remove_file(f.ident) if f
      end

=begin rdoc
Instantiate a Process object from Project or WorkingData Hash.
=end
      def process(ident)
        (@project || @working_data).process ident
      end

      def processes
        (@project || @working_data).processes
      end

      def add_process(cmd, fname=nil, arch_info=nil, ident=nil)
        (@project || @working_data).add_process(cmd, fname, arch_info, ident)
      end

      def remove_process(ident)
        p = process(ident)
        (@project || @working_data).remove_process(p.ident) if p
      end

      # ----------------------------------------------------------------------

      def item_at_obj_path(objpath)
        return (@project || @working_data) if objpath == '/'
        (@project || @working_data).item_at_obj_path(objpath)
      end

      def address(ident)
        # attempt to parse ident as a VMA
        vma = Integer(ident) rescue nil

        if vma
          find_address(vma)
        else
          # assume ident is an object path, and go from there
          # TODO: allow shorthand notation such as @ for rev
          item_at_obj_path(ident)
        end
      end

      def find_address(vma, rev=nil)
        processes.each do |p|
          m = p.map_containing vma
          return m.address(vma, rev) if m
        end

        files.each do |f|
          s = f.section_containing vma
          return s.address(vma, rev) if m
        end
        nil
      end

      # ----------------------------------------------------------------------
      # Serialization

=begin rdoc
Invoke project#save, if applicable.
Has no effect on in-memory (JSON-serialized) Pipeline projects.
=end
      def save(msg=nil)
        @project.save(msg) if @project and (project.respond_to? :save)
      end

=begin rdoc
Instantiate a Pipeline object from a Hash. This is invoked when de-serializing 
from JSON.
=end
      def self.from_hash(hash)
        wd_h = hash[:working_data].inject({}) { |h,(k,v)| h[k.to_sym] = v; h }

        # build ordered (by dependency) list of data types to load
        data_types = build_ordered_datatypes(wd_h)

        # for each datatype, convert WD Hash entry to a Hash of Bgo Objects 
        wdata = data_types.inject(WorkingData.new) do |wd, key| 
          wd[key.to_sym] = fill_wd_hash(MODELITEM_CLASS[key], wd_h[key], wd); wd
        end

        state = self.new wdata, hash[:command_history]
        state.project_path = hash[:project_path]
        state
      end

      def to_json(*arr)
        self.to_hash.to_json(*arr)
      end

      def to_hash
        { :command_history => @command_history,
          :working_data => @working_data.to_hash,
          :project_path => @project_path }
      end

=begin rdoc
Fill working_data entry for datatype.
'obj' is a Hash or Array of ModelItem or ModelItemFactory classes.
=end
      def self.fill_wd(cls, obj, datastore)
        (obj.respond_to? :values) ? fill_wd_hash(cls, obj, datastore) : 
                                    fill_wd_array(cls, obj, datastore)
      end

=begin rdoc
Fill working_data Hash from contents of hash
=end
      def self.fill_wd_hash(cls, hash, datastore)
        return cls.from_hash(hash) if MODELITEM_SINGLE.include? cls

        hash.inject({}) do |h,obj|
          h[obj[:ident]] = cls ? cls.from_hash(obj, datastore) : obj; h
        end
      end

=begin rdoc
Fill working_data Array from contents of array
=end
      def self.fill_wd_array(cls, array, datastore)
        array.inject([]) do |arr,obj|
          arr << cls ? cls.from_hash(obj, datastore) : obj; arr
        end
      end

=begin rdoc
Return an array of working_data Hash keys ordered so that dependencies
are loaded first
=end
      def self.build_ordered_datatypes(hash)
        data_types = []
        hash.keys.each do |key|
          next if (data_types.include? key)
          cls = MODELITEM_CLASS[key]
          if ! cls
            data_types << key
            next
          end

          # ensure class dependencies are loaded before class is loaded
          cls.dependencies.each do |dep|
            hash.keys.each do |dkey|
              next if dkey == key || (data_types.include? dkey)
              dcls = MODELITEM_CLASS[dkey]
              data_types << dkey if (! dcls) || (dcls.ancestors.include? dep)
            end
          end

          data_types << key 
        end
        data_types
      end
    end

=begin rdoc
Working Data object.
This is a Hash that responds to top-level Project accessor methods, in order
to provide a unified interface during from_hash.
=end
    class WorkingData < Hash
      def image(ident)
        (self[Bgo::Image.path_elem.to_sym] || {})[ident]
      end

      def images
        (self[Bgo::Image.path_elem.to_sym] || {}).values
      end

      def add_image(buf)
        self[Bgo::Image.path_elem.to_sym] ||= {}
        img = Bgo::Image.new( buf )
        self[Bgo::Image.path_elem.to_sym][img.ident] ||= img
        img
      end

      def add_virtual_image(fill, size)
        self[Bgo::Image.path_elem.to_sym] ||= {}
        img = Bgo::VirtualImage.new( fill, size ) 
        self[Bgo::Image.path_elem.to_sym][img.ident] ||= img
        img
      end

      def add_remote_image(img_path, sz, img_ident)
        self[Bgo::Image.path_elem.to_sym] ||= {}
        img = Bgo::RemoteImage.new( img_path, size, img_ident ) 
        self[Bgo::Image.path_elem.to_sym][img.ident] ||= img
        img
      end

      def remove_image(ident)
        (self[Bgo::Image.path_elem.to_sym] || {}).delete ident
      end

      def file(ident)
        (self[Bgo::TargetFile.path_elem.to_sym] || {})[ident]
      end

      def files
        (self[Bgo::TargetFile.path_elem.to_sym] || {}).values
      end

      def add_file(path, proj_path='')
        buf = File.binread(path)
        img = add_image( buf )
        file_path = path
        if proj_path
          fname = File.basename(path)
          file_path = (proj_path.empty?) ? fname : File.join(proj_path, fname)
        end

        add_file_for_image(file_path, img, 0, nil)
      end

      def add_file_for_image(path, img, off=0, size=nil)
        self[Bgo::TargetFile.path_elem.to_sym] ||= {}
        f = Bgo::TargetFile.new( File.basename(path), path, img, off, size )
        self[Bgo::TargetFile.path_elem.to_sym][f.ident] ||= f
        f
      end

      def remove_file(ident)
        h = self[Bgo::TargetFile.path_elem.to_sym] || {}
        (h.include? ident) ? h.delete(ident) : \
                             h.each { |id, f| f.remove_file ident }
      end

      def process(ident)
        (self[Bgo::Process.path_elem.to_sym] || {})[ident]
      end

      def processes
        (self[Bgo::Process.path_elem.to_sym] || {}).values
      end

      def add_process(cmdline, fname=nil, arch_info=nil, ident=nil)
        self[Bgo::Process.path_elem.to_sym] ||= {}
        ident ||= (self[Bgo::Process.path_elem.to_sym].keys.max || 999).succ
        p = Bgo::Process.new( ident, cmdline, fname, nil )
        self[Bgo::Process.path_elem.to_sym][p.ident] ||= p
        p
      end

      def remove_process(ident)
        (self[Bgo::Process.path_elem.to_sym] || {}).delete ident
      end

      def item_at_obj_path(objpath)
        return if (! objpath) or (objpath.empty?)

        sep = File::SEPARATOR
        c_type, c_ident, *rest = objpath.sub(/#{sep}*/, '').split(sep)
        rest = File.join(rest)

        type_sym = c_type.to_sym
        if self[type_sym]
          ident = fix_ident(type_sym, c_ident)
          instantiate_child(self[type_sym][ident], rest)

        else
          values.each do |h|
            h.values.each do |obj|
              child = instantiate_child(obj, objpath)
              return child if child
            end
          end

          nil
        end
      end

      def instantiate_child(obj, objpath)
        return obj if objpath.empty?

        (obj.respond_to? :instantiate_child) ? \
            obj.instantiate_child(objpath, false, true) : nil
      end

      def fix_ident(sym, ident)
        sym == :process ? Integer(ident) : ident
      end

      def to_hash
        inject({}) do |h,(k,v)| 
          arr = (v.respond_to? :values) ? v.values : v
          if arr.respond_to? :map
            # value is a coclletion of objects
            h[k] = arr.map { |obj| obj.to_hash }
          else
            # value is an object, e.g. Project
            h[k] = arr.to_hash
          end
          h
        end
      end
    end

  end
end
