#!/usr/bin/env ruby
# :title: Bgo::Project
=begin rdoc
BGO Project object.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'time'

require 'bgo'
require 'bgo/version'
require 'bgo/model_item'

# =============================================================================

module Bgo

=begin rdoc
Base class for Project object.
Also serves as in-memory object when there is no backing store.
=end
  class Project < ModelRootItem

=begin rdoc
Name of project. Default is 'Untitled'.
=end
    attr_accessor :name

=begin rdoc
Description of project. Default is 'BGO Project'
=end
    attr_accessor :description
    alias :descr :description
    alias :descr= :description=

=begin rdoc
Version of BGO used to create the project.
=end
    attr_reader :bgo_version

=begin rdoc
Timestamp for project creation.
=end
    attr_reader :created

    DEFAULT_NAME='Untitled'
    DEFAULT_DESCR='BGO Project'
    DEFAULT_PID = 1000


=begin rdoc
Instantiate a project with the given name and description.
 NOTE: auto-naming of project (e.g. to target name) is responsibility
       of application.
=end
    def initialize(name=DEFAULT_NAME, descr=DEFAULT_DESCR)
      @name = name || DEFAULT_NAME
      @description = descr || DEFAULT_DESCR
      @images = {}
      @files = {}
      @packets = {}
      @processes = {}

      @bgo_version = Bgo::VERSION
      @created = Time.now()

      super()
    end

    def ident
      name.gsub(/[^-_.,[:alnum:]]/, '')
    end

=begin rdoc
Open an in-memory (temporary) project.
If a block has been provided, the Project object is yielded to the block, then
closed.

This method is part of the API for Repository-backed projects, and has no
effect on in-memory projects -- it simply returns a new Project.

See Bgo::Git::Project.open.
=end
    def self.open(path=nil, &block)
      project = self.new

      return project if ! block_given?
      yield project
      project.close true
      project
    end

=begin rdoc
Close project. This invokes Project#autosave if autosave is true.
Note that Project#close and Project#autosave have no effect on in-memory BGO
Data Model objects.

See Bgo::Git::Project#close.
=end
    def close(autosave=true)
      # TODO: notify subscribers
      self.autosave if autosave
    end

=begin rdoc
Perform any automatic saving needed by Project. This has no effect on in-memory
BGO Project objects.
See Bgo::Git::Project#autosave.
=end
    def self.autosave
      true
    end

# ----------------------------------------------------------------------
    def self.child_iterators
      [:images, :files, :packets, :processes]
    end

=begin rdoc
The default child object for a Project is Image.
=end
    def self.default_child
      :image
    end

=begin rdoc
Override the ModelItemObject default method for generating ObjectPath, as
Project has no parent ModelItem object.

Note that this methods returns the empty string unless 'root' is true, as
Project is the root of the ModelItem object tree.
=end
    def obj_path(rel=false, root=false)
      root ? self.class.name.downcase + ':' + ident : ''
    end

# ----------------------------------------------------------------------
=begin rdoc
Iterator for TargetFile objects in project. If block is not provided, an
Enumerator is returned. If ident_only is true, only the TargetFile idents
will be yielded.
=end
    def files(ident_only=false, &block)
      return to_enum(:files, ident_only) if ! block_given?
      @files.values.sort { |a,b| a.ident <=> b.ident }.each do |file|
        yield(ident_only ? file.ident : file)
      end
    end
    alias :target_files :files

=begin rdoc
Return File object for the given ident. 
Note: If ident is not the name of a top-level File, all files are searched
for a child that matches ident. The first match is returned.
=end
    def file(ident)
      file = @files[ident]
      if ! file
        @files.each { |id, f| file ||= f.file(ident) }
      end
      file
    end
    alias :target_file :file

=begin rdoc
Add a TargetFile to the project. This creates an Image for the TargetFile
contents.
If proj_path is provided, it will be used as the path (and therefore, the ident)
of the TargetFile object in the project. 
Examples:
  # Add the file 'sc_server' as 'sc_server'. This is the default behavior.
  proj.add_file('/usr/local/bin/sc_server', '')
  # Add the file 'sc_server' as 'bin/sc_server'
  proj.add_file('/usr/local/bin/sc_server', 'bin')
  # Add the file 'sc_server' as '/usr/local/bin/sc_server'
  proj.add_file('/usr/local/bin/sc_server', nil)
=end
    def add_file(path, proj_path='')
      buf = File.binread(path)
      img = add_image( buf )

      file_path = path
      if proj_path
        fname = File.basename(path) 
        file_path = (proj_path.empty?) ? fname : File.join(proj_path, fname)
      end

      f = add_file_for_image( file_path, img, 0, buf.length)
      if file_path != proj_path
        f.properties[:original_path] = path
      end
      f
    end
    alias :add_target_file :add_file

=begin rdoc
Add a TargetFile for an existing Image to the project.
=end
    def add_file_for_image(path, img, off=0, size=nil)
      f = Bgo::TargetFile.new( File.basename(path), path, img, off, size )
      add_file_object f
    end

=begin rdoc
Remove TargetFile from project.
=end
    def remove_file(ident)
      (@files.include? ident) ? @files.delete(ident) : \
                                @files.each { |id, f| f.remove_file ident }
    end
    alias :remove_target_file :remove_file

# ----------------------------------------------------------------------
=begin rdoc
Iterator for Packet objects in project. If block is not provided, an
Enumerator is returned. If ident_only is true, only the Packet idents
will be yielded.
=end
    def packets(ident_only=false, &block)
      return to_enum(:packets, ident_only) if ! block_given?
      @packets.values.sort { |a,b| a.ident <=> b.ident }.each do |pkt|
        yield(ident_only ? pkt.ident : pkt)
      end
    end

=begin rdoc
Return Packet object for the given ident. 
=end
    def packet(ident)
      @packets[ident]
    end

=begin rdoc
Add a Packet for binary String.
=end
    def add_packet(pkt_ident, bytes)
      img = add_image( bytes )
      add_packet_for_image(pkt_ident, img, 0, bytes.length)
    end

=begin rdoc
Add a Packet for an existing Image to the project.
=end
    def add_packet_for_image(pkt_ident, img, img_off=0, sz=nil)
      p = Bgo::Packet.new( pkt_ident, img, img_off, sz )
      add_packet_object p
    end

=begin rdoc
Remove Packet from project.
=end
    def remove_packet(ident)
      @packets.delete(ident)
    end

# ----------------------------------------------------------------------
=begin rdoc
Iterator for Image objects in project. If block is not provided, an Enumerator 
is returned. If ident_only is true, only the Imag idents will be yielded.
=end
    def images(ident_only=false, &block)
      return to_enum(:images, ident_only) if ! block_given?
      @images.values.sort { |a,b| a.ident <=> b.ident }.each do |image|
        img = ident_only ? image.ident : image
        yield img
      end
    end

=begin rdoc
Return an Image object for the specified ident (SHA).
=end
    def image(ident)
      @images[ident]
    end

=begin rdoc
Add a binary image (i.e. raw, unnamed data) to Project.
=end
    def add_image(buf)
      add_image_object Bgo::Image.new(buf)
    end

=begin rdoc
Add a virtual binary image (i.e. a memory range initialized to a value, like
.bss) to Project.
=end
    def add_virtual_image(fill, size)
      add_image_object Bgo::VirtualImage.new(fill, size)
    end

=begin rdoc
Add a remote image to Project. This is used to refer to a binary file which
lies outside of the Project, which can be useful when sharing Projects, or
to minimize the size of a Project repo.

Note that size and ident can be supplied, if known, in order to create a
RemoteImage for a file which does not currently exist.
=end
    def add_remote_image(img_path, sz=nil, img_ident=nil)
      add_image_object Bgo::RemoteImage.new(img_path, sz, img_ident)
    end

=begin rdoc
Remove image from project.
=end
    def remove_image(ident)
      @images.delete ident
    end

# ----------------------------------------------------------------------
=begin rdoc
Iterator for Process objects in project. If block is not provided, an Enumerator
is returned. If ident_only is true, only the Process idents will be yielded.
=end
    def processes(ident_only=false, &block)
      return to_enum(:processes, ident_only) if ! block_given?
      @processes.values.sort { |a,b| a.ident <=> b.ident }.each do |process|
        p = ident_only ? process.ident : process
        yield p
      end
    end

=begin rdoc
Return a Process object for the specified ident (PID).
=end
    def process(ident)
      @processes[ident.to_i]
    end

=begin rdoc
Add a process to the project
=end
    def add_process(command, fname=nil, arch_info=nil, ident=nil)
      ident ||= (@processes.empty?) ? DEFAULT_PID : @processes.keys.max.succ
      p = Bgo::Process.new( ident, command, fname, arch_info )
      add_proc_object p
    end

=begin rdoc
Remove Process from project.
=end
    def remove_process(ident)
      @processes.delete ident
    end

    # ----------------------------------------------------------------------
    # TODO: object type system
    def obj_type(ident)
      # TODO
    end

    def add_obj_type(t)
      # TODO
    end

    def obj_types(ident_only=true, &block)
      return to_enum(:obj_types, ident_only) if ! block_given?
      # TODO
    end

    def remove_obj_type(ident)
      # TODO
    end

    # ----------------------------------------------------------------------
=begin
Invoke the :load_target method for the specified Plugin on the list of 
filenames.
The effect of this method is plugin-specific. The Plugin may add the files
as TargetFile objects, create a Process object, and load the files into the
process before performing disassembly.
=end
    def load_target!(paths, plugin, opts={})
      args = :load_target, self, paths, opts
      plugin = Application::PluginManager.find(plugin) if \
               (plugin.kind_of? String)

      if ! plugin
        $stderr.puts "No :load_target plugin available"
        return false
      end

      plugin.spec_invoke(*args)
    end
  
# ----------------------------------------------------------------------
=begin rdoc
Accessor for the AuthoredComments of the Project object.

If recurse is true, this also invokes the comments() method on all children,
yielding each AuthoredComments object to the provided block or returning an 
Enumerator if no block is passed.
=end
    def comments(recurse=false, &block)
      return super() if ! recurse
      return to_enum(:comments, recurse) if ! block_given?
      super().each(&block)
      descendants { |c| c.comments.each(&block) }
    end

=begin rdoc
Accessor for the Tags Array of the Project object.

If recurse is true, this also invokes the tags() method on all children, 
yielding each tag Array to the provided block or returning an Enumerator if no 
block is passed.
=end
    def tags(recurse=false, &block)
      return super() if ! recurse
      return to_enum(:tags, recurse) if ! block_given?
      super().each(&block)
      descendants { |c| c.tags.each(&block) }
    end

=begin rdoc
Accessor for the properties Hash of the Project object.

If recurse is true, this also invokes the properties() method on all children,
yielding each properties Hash to the provided block or returning an 
Enumerator if no block is passed.
=end
    def properties(recurse=false, &block)
      return super() if ! recurse
      return to_enum(:properties, recurse) if ! block_given?
      super().each(&block)
      descendants { |c| c.properties.each(&block) }
    end

=begin rdoc
This examines all children (using ModelItem#descendants) and yields the 
contents of all Address objects whose contents are Strings.
NOTE: This is not yet implemented.
=end
    def strings(&block)
      return to_enum(:strings) if ! block_given?
      descendants do |c|
        next if (! c.kind_of? Address)
        next if (! c.data?)
        #TODO: return contents if type == string
      end
    end

=begin rdoc
This yields the symbol table of every File and Process object in the Project.
If a block is not provided, an Enumerator is returned.
=end
    def symbols(&block)
      return to_enum(:symbols) if ! block_given?
      files.each { |f| f.symtab(&block) }
      packets.each { |p| p.symtab(&block) }
      processes.each { |p| p.symtab(&block) }
    end

# ----------------------------------------------------------------------

=begin rdoc
Subscribe to change notifications from Project.
This is disabled in in-memory Project objects, as there is no object
chain linking BGO objects to their projects (though there could be
a @project member set during project.add_*).
This will be implemented if there is a need for it.
=end
    def subscribe(ident, func=nil, obj=nil, &block)
      # nop
    end

=begin rdoc
Notify all subscribers that a change has happened.
See Project#subscribe.
=end
    def notify
      #nop
    end

=begin rdoc
Unsubscribe from change notifications from Project.
See Project#subscribe.
=end
    def unsubscribe(ident)
      # nop
    end

# ----------------------------------------------------------------------
      # meta...

    def to_s
      "Project '#{name}'"
    end

    def inspect
      "Project '#{name}' : #{description}"
    end

# ----------------------------------------------------------------------

=begin rdoc
Generate a clean Hash (containing no ModelItem children) representing Project.
This is used in conversion to JSON.
=end
    def to_core_hash
      {
        :name => @name,
        :description => @description,
        :bgo_version => @bgo_version,
        :created => @created
      }.merge(to_modelitem_hash)
    end

=begin rdoc
Generate a complete Hash representing Project and all of its children.
=end
    def to_hash
      to_core_hash.merge( { 
        Image.path_elem.to_sym => images.map { |i| i.to_hash },
        TargetFile.path_elem.to_sym => files.map { |f| f.to_hash },
        Packet.path_elem.to_sym => packets.map { |p| p.to_hash },
        Process.path_elem.to_sym => processes.map { |p| p.to_hash }
      } )
    end
    alias :to_h :to_hash

    def fill_from_hash(h)
      @name = h[:name].to_s
      @description = h[:description].to_s
      @bgo_version = h[:bgo_version].to_s if h[:bgo_version]
      @created = Time.parse(h[:created]) if h[:created]
      fill_from_modelitem_hash h

      (h[Image.path_elem.to_sym] || []).each do |hh|
        img = (hh[:virtual] ?
              VirtualImage.from_hash(hh, self) : Image.from_hash(hh, self))
        add_image_object img
      end

      (h[TargetFile.path_elem.to_sym] || []).each do |hh|
        add_file_object TargetFile.from_hash(hh, self)
      end

      (h[Packet.path_elem.to_sym] || []).each do |hh|
        add_packet_object Packet.from_hash(hh, self)
      end

      (h[Process.path_elem.to_sym] || []).each do |p|
        add_proc_object Process.from_hash(hh, self)
      end
      self
    end

    def self.from_hash(h)
      self.new.fill_from_hash(h)
    end

    protected

    def add_image_object(obj)
      if (obj && (! @images.include? obj.ident))
        obj.modelitem_init_parent self
        @images[obj.ident] = obj
      end
      obj
    end

    def add_file_object(obj)
      if (obj && (! @files.include? obj.ident))
        obj.modelitem_init_parent self
        @files[obj.ident] = obj
      end
      obj
    end

    def add_packet_object(obj)
      if (obj && (! @packets.include? obj.ident))
        obj.modelitem_init_parent self
        @packets[obj.ident] = obj
      end
      obj
    end

    def add_proc_object(obj)
      if (obj && (! @processes.include? obj.ident))
        obj.modelitem_init_parent self
        @processes[obj.ident] = obj
      end
      obj
    end

    def instantiate_child_from_ident(sym, ident)
      super sym, (sym == :process ? Integer(ident) : ident)
    end

  end
end
