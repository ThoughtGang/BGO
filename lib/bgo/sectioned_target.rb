#!/usr/bin/env ruby
# :title: Bgo::SectionedTarget
=begin rdoc
==BGO SectionedTarget
<i>Copyright 2013 Thoughtgang <http://www.thoughtgang.org></i>

This is a module containing instance methods common to Target objects that have
Sections.
=end  

require 'bgo/section'

module Bgo

=begin rdoc
A TargetObject that can be divided into Sections, such as a TargetFile or a
Packet.

Note: TargetObject must have been included before SectionedTargetObject.
=end
  module SectionedTargetObject

=begin rdoc
The Image object for the Target contents. Note: the Image object may be
larger than the Target object, as it can contain multiple targets. Use
SectionedTarget#contents to get the raw binary contents of the target.
=end
    attr_reader :image

=begin rdoc
The offset of the start of this Target in the Image object. Usually 0, unless
the Image object is a container or archive (e.g. a tar file).
=end
    attr_reader :image_offset

=begin rdoc
The size of the Target in bytes. Usually the same size as the Image object, 
unless the Image object is a container or archive (e.g. a tar file).
=end
    attr_reader :size

=begin rdoc
Ident object for Target.
=end
    attr_accessor :ident_info

    def sectioned_target_init(img, img_offset=nil, sz=nil)
      @image = img
      @image_offset = img_offset || 0
      @size = sz || img.size
      @sections = {}
      @parsed = false
      @ident_info = nil
    end

=begin rdoc
The SHA digest of the Target contents.
=end
    def digest
      image.ident
    end


=begin rdoc
Return the raw binary contents of the Target.
=end
    def contents
      image.contents[image_offset, size]
    end

=begin rdoc
Return a binary substring of the Target image contents
=end
    def [](*args)
      contents.[](*args)
    end

# ----------------------------------------------------------------------
=begin rdoc
List Section objects defined in Target.
=end
    def sections(ident_only=false, &block)
      return to_enum(:sections, ident_only) if ! block_given?
      @sections.values.each do |sec|
        yield(ident_only ? sec.ident : sec)
      end
    end

=begin rdoc
Enumerator of Sections sorted by name.
=end
    def sections_sorted(&block)
      return to_enum(:sections_sorted) if ! block_given?
      @sections.values.sort { |a,b| 
        # Tricky sort: ident is often an index but can be an abritrary string
        #              depending on what the :parse_file plugin decided.
        #              If a.to_i == b.to_i and a != b, to_i failed (use string)
        (a.ident.to_i == b.ident.to_i && a.ident != b.ident) ?
        a.ident <=> b.ident : a.ident.to_i <=> b.ident.to_i 
                            }.each { |sec| yield sec if block_given? }
    end

=begin rdoc
Enumerator of Sections sorted by offset.
=end
    def sections_ordered(&block)
      return to_enum(:sections_ordered) if ! block_given?
      @sections.values.sort { |a,b| a.offset <=> b.offset 
                            }.each { |sec| yield sec if block_given? }
    end

=begin rdoc
Instantiate Section object for ident in Target.
=end
    def section(ident)
      @sections[ident]
    end

=begin rdoc
Define a Section object with given ident of size bytes at offset in Target.
=end
    def add_section(s_ident, off=0, sz=nil, name=nil, 
                    flgs=Section::DEFAULT_FLAGS, arch_info=nil)
      sz ||= size - off
      s = Bgo::Section.new(s_ident, name, image, image_offset + off, off, sz, 
                           flgs)
      s.arch_info = arch_info if arch_info
      add_section_object s
    end

=begin rdoc
Remove Section object for ident in Target.
=end
    def remove_section(ident)
      @sections.delete(ident)
    end

=begin rdoc
Return Section object containing offset
=end
    def section_containing(offset)
      sections.select { |s| s.contains? offset }.first
    end

=begin rdoc
Re-implementation of TargetObject#address_containers.
Note that this wraps SectionedTargetObject#sections instead of aliasing it, so 
that the sections() method will be called by subclasses such as Git::Section.
=end
    def address_containers(ident_only=false, &block)
      sections(ident_only, &block)
    end

=begin rdoc
Re-implementation of TargetObject#address_container.
Note that this wraps SectionedTargetObject#section instead of aliasing it, so 
that the section() method will be called by subclasses such as Git::Section.
=end
    def address_container(ident)
      section(ident)
    end

=begin rdoc
Return Address object for offset, if it exists.
This is a convenience routine that finds the Section containing the offset, 
then invokes its address() method.
=end
    def address(offset, revision=nil)
      s = section_containing(offset)
      s ? s.address(offset, revision) : nil
    end

=begin rdoc
Iterate over Address objects defined in Target.
This just calls Section#addresses for every Section.
=end
    def addresses(rev=nil, &block)
      return to_enum(:addresses, rev) if ! block_given?
      sections.each { |s| s.addresses(rev).each { |a| yield a } }
    end

    # ----------------------------------------------------------------------

=begin rdoc
Parse the Target using a plugin supporting the :parse_file specification. 
This will create sections and symbols in the Target.

The plugin argument can be a Plugin object or a String naming a plugin.
If no plugin is selected, the plugin with the highest confidence is used.

Returns true on success, false otherwise.
Note: This will raise a NameError if the PluginManager service is not started.
=end
    def parse!(plugin=nil, opts={})
      args = :parse_file, self, opts

      if plugin
        plugin = Application::PluginManager.find(plugin) if \
                (plugin.kind_of? String)
        $stderr.puts "#{plugin.inspect} not found" if ! plugin
      else
        plugin = Application::PluginManager.fittest_providing(*args)
      end

      if ! plugin
        $stderr.puts "No :parse_file plugin available"
        return false
      end

      h = plugin.spec_invoke(*args)
      if h && (! h.empty?)
        @parsed = true
        properties[:parse_plugin] = plugin.canon_name
      end
      parsed?
    end

    def parsed?
      @parsed
    end

=begin rdoc
Identify the Target using a plugin supporting the :ident specification..

The plugin argument can be a Plugin object or a String naming a plugin.
If no plugin is selected, the plugin with the highest confidence is used.

Returns true on success, false otherwise.
Note: This will raise a NameError if the PluginManager service is not started.
=end
    def ident!(plugin=nil)
      path_str = (self.respond_to? :full_path) ? full_path : ''
      args = :ident, image.contents, path_str

      if plugin
        plugin = Application::PluginManager.find(plugin) if \
                (plugin.kind_of? String)
        $stderr.puts "#{plugin.inspect} not found" if ! plugin
      else
        plugin = Application::PluginManager.fittest_providing(*args)
      end

      if ! plugin
        $stderr.puts "No :ident plugin available"
        return false
      end
          
      self.ident_info = plugin.spec_invoke(*args)
      properties[:ident_plugin] = plugin.canon_name if identified?
      identified?
    end

    def identified?
      (ident_info != nil) && (ident_info != Ident::unrecognized)
    end


    # ----------------------------------------------------------------------
    def to_sectioned_target_core_hash
      { 
        :image => @image.ident,
        :image_offset => @image_offset,
        :size => @size,
        :parsed => @parsed,
        :ident_info => (@ident_info ? @ident_info.to_hash : nil)
      }
    end

    def to_sectioned_target_hash
      { :sections => sections.to_a }
    end

    def fill_from_sectioned_target_hash(h, proj=nil)
      (h[:sections] || []).each do |s| 
        hh = s.to_hash
        ai = hh[:arch_info] ? ArchInfo.from_hash(hh[:arch_info]) : nil
        flags = (hh[:flags] || []).map { |f| f.to_sym }

        sec = add_section( hh[:ident].to_s, hh[:file_offset].to_i, 
                           hh[:size].to_i, hh[:name].to_s, flags, ai )
        sec.fill_from_hash(hh)
      end
    end

    # ----------------------------------------------------------------------
    protected

    def add_section_object(obj)
      if (obj && (! @sections.include? obj.ident))
        obj.modelitem_init_parent self
        target_init_ac obj
        @sections[obj.ident] = obj
      end
      obj
    end 

  end

end
