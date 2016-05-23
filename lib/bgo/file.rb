#!/usr/bin/env ruby
# :title: Bgo::TargetFile
=begin rdoc
==BGO TargetFile object
<i>Copyright 2013 Thoughtgang <http://www.thoughtgang.org></i>

A TargetFile associates an on-disk file with an Image object. A TargetFile can
contain nested child TargetFile objects (e.g. archive files).

Note: the name TargetFile is used instead of File to avoid conflicts with the
Ruby File class.
=end  

require 'bgo/image'
require 'bgo/ident'
require 'bgo/model_item'
require 'bgo/target'
require 'bgo/sectioned_target' 

module Bgo

=begin rdoc
Base class for File object.
Also servers as in-memory object when there is no backing store.
=end
  class TargetFile
    extend Bgo::ModelItemClass
    include Bgo::ModelItemObject
    include Bgo::TargetObject
    include Bgo::SectionedTargetObject 

=begin rdoc
The name of the file, obtained from File.basename()
=end
    attr_reader :name
=begin rdoc
The path to the original file.
=end
    attr_reader :full_path
=begin rdoc
The directory of the original file.
=end
    attr_reader :dir
=begin rdoc
Files contained in this file object. An archive or container file will have
TargetFile objects in this array.
=end
    attr_reader :child_files

    def self.path_elem
      'file'
    end

    def self.dependencies
      [ Bgo::Image ]
    end

    def self.child_iterators
      # TODO: blocks? symbols?
      [:sections, :files]
    end

    def self.default_child
      :section
    end

=begin rdoc
Instantiate a File object for an Image object with the given name and path. 

Note that TargetFile objects can be nested: an archive or container file can
contain TargetFile objects. These child objects use the offset and size
members to identify the bytes in TargetFile#image that make up the contents
of the child file. To create a child in a container TargetFile, use
TargetFile#add_file.

The path is used to construct a unique ident for the file; therefore, the
path must be unique among all files, including child files.
=end
    def initialize( name, path, img, img_offset=nil, sz=nil )
      @name = name
      @full_path = path
      @dir = File.dirname(path)
      @child_files = {}
      sz ||= img.size
      modelitem_init
      target_init
      sectioned_target_init img, img_offset, sz
    end

=begin rdoc
A unique name for this file, derived from path name. This replaces all path
separators ('/') with carets ('^').
=end
    def ident
      full_path.gsub(/[\\\/]+/, '^')
    end

=begin rdoc
Open a ruby File object for this File. The File object is opened in read-only
mode.
=end
    def open
      f = File.open(full_path, 'rb')
      return f if not block_given?
      yield f
      f.close
    end

  # ----------------------------------------------------------------------
=begin rdoc
List File objects contained in File.
=end
    def files(ident_only=false, &block)
      return to_enum(:files, ident_only) if ! block_given?
      @child_files.values.sort { |a,b| a.ident <=> b.ident }.each do |f|
        yield(ident_only ? f.ident : f)
      end
    end

=begin rdoc
Return child TargetFile object for the given ident.
Note: If ident does not refer to a direct child, the first child file containing
a file that matches ident is returned.
=end
    def file(ident)
      file = @child_files[ident]
      if ! file
        @child_files.each { |id, f| file ||= f.file(id) }
      end
      file
    end

=begin rdoc
Add a (child) file to this (container) file. This assumes the file is contained 
in TargetFile#image.
=end
    def add_file(name, path, offset, size)
      add_discrete_file(name, path, image, offset, size )
    end

=begin rdoc
Add a (child) file to this (container) file, using the specified Image.

Note: this is used instead of TargetFile#add_file in cases where the child
file contents are NOT contained in TargetFile#image : for example, when a file
has been extracted from a compressed (e.g. .zip or .gz) file to a standalone
Image object.
=end
    def add_discrete_file(name, path, img, offset=0, size=nil)
      add_file_object Bgo::TargetFile.new( name, path, img, offset, size )
    end

=begin rdoc
Remove child TargetFile object for the given ident.
Note: If ident does not refer to a direct child, remove_file is called for all
children.
=end
    def remove_file(ident)
      rv = false
      if @child_files.include? ident
        @child_files.delete ident
        rv = true
      else
        @child_files.each { |id, f| rv ||= g.remove_file ident }
      end
      rv
    end


  # ----------------------------------------------------------------------
    def to_s
      "File '#{name}'"
    end

    def inspect
      str = "File '#{name}' { Ident '#{ident}', Path '#{full_path}', Image #{image.ident} }"
      str
    end

  # ----------------------------------------------------------------------
    def to_core_hash
      {
        :name => @name,
        :dir => @dir,
        :full_path => @full_path,
        :ident => ident
      }.merge( to_modelitem_hash ).merge( to_sectioned_target_core_hash )
    end

    def to_hash
      to_core_hash.merge(to_target_hash).merge(to_sectioned_target_hash).merge( 
          { :files => files.to_a } )
    end
    alias :to_h :to_hash

    def fill_from_hash(h, proj=nil)
      fill_from_modelitem_hash h
      fill_from_target_hash h
      fill_from_sectioned_target_hash h

      @parsed = h[:parsed]
      @ident_info = Bgo::Ident.from_hash(h[:ident_info]) if h[:ident_info]
      (h[:files] || []).each do |f| 
        hh = f.to_hash
        file = add_file(hh[:name].to_s, hh[:full_path].to_s, 
                        hh[:image_offset].to_i , hh[:size].to_i )
        file.fill_from_hash(hh, proj)
      end
      self
    end

    def self.from_hash(h, proj=nil)
      return nil if (! h) or (h.empty?)
      img_ident = h[:image]
      img = h[:image_obj]
      if proj
        img ||= proj.image(img_ident)
        img ||= proj.item_at_obj_path img_ident
      end
      
      raise "Invalid Image object #{img_ident}' is nil" if \
            (! img.kind_of? Bgo::Image)
      obj = self.new(h[:name].to_s, h[:full_path].to_s, img, 
                     h[:image_offset].to_i, h[:size].to_i)
      obj.fill_from_hash h, proj
      obj
    end

    # ----------------------------------------------------------------------
    protected

    def add_file_object(obj)
      if (obj && (! @child_files.include? obj.ident))
        obj.modelitem_init_parent self
        @child_files[obj.ident] = obj
      end
      obj
    end 

  end

end
