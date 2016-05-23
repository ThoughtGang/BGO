#!/usr/bin/env ruby
# :title: Bgo::Process
=begin rdoc
BGO Process object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end  

# TODO: can processes nest, like files?

require 'bgo/arch_info'
require 'bgo/image'
require 'bgo/model_item'
require 'bgo/target'

module Bgo

=begin rdoc
Base class for Process object.
Also serves as in-memory object when there is no backing store.
=end
  class Process
    extend Bgo::ModelItemClass
    include Bgo::ModelItemObject
    include Bgo::TargetObject

=begin rdoc
Exception raised if a created Map overlaps with an existing Map.
=end
    class MapOverlapError < RuntimeError; end

=begin rdoc
The ident of the process
=end
    attr_reader :ident
=begin rdoc
The command line for the process
=end
    attr_accessor :command
=begin rdoc
The name of the File object for the main executable of this process (if
applicable).
Note: This member is unused and is for descriptive purposes only.
=end
    attr_accessor :filename

=begin rdoc
Architecture information for the Process. This is an ArchInfo object.
=end
    attr_accessor :arch_info

    def self.dependencies
      [ Bgo::Image ]
    end

    def self.child_iterators
      # TODO: block? symbols?
      [ :maps ]
    end

    def self.default_child
      :map
    end

=begin rdoc
Instantiate a Process object with the given comment.
=end
    def initialize( ident, command, filename=nil, arch_info=nil )
      @ident = ident
      @command = command
      @filename = filename
      @arch_info = arch_info
      @maps = {}
      modelitem_init
      target_init
    end

=begin rdoc
Start Address of process. This is always 0.
This method exists to allow a Process to be treated like an AddressContainer,
if necessary.
=end
    def start_addr
      0
    end

=begin rdoc
Size of process. This is essentially MAX_INT.
This method exists to allow a Process to be treated like an AddressContainer,
if necessary.
=end
    def size
      Float::MAX.to_i
    end

# ----------------------------------------------------------------------
=begin rdoc
Return a binary substring of the Process memory contents
=end
    def [](*args)
      # TODO: 
      # maps = maps_for_range( args )
      # map.image.[](*args)
      raise NotImplementedError
    end


=begin rdoc
List Map objects defined in Process.
=end
    def maps(ident_only=false, &block)
      return to_enum(:maps, ident_only) if ! block_given?
      @maps.values.sort { |a,b| a.start_addr <=> b.start_addr }.each do |map|
        yield(ident_only ? map.start_addr : map)
      end
    end

    alias :address_space :maps

=begin rdoc
Instantiate a Map object for load_address in Process.
=end
    def map(load_address)
      @maps[load_address]
    end

=begin rdoc
Define a Map object for Image at load_address in Process.
=end
    def add_map(image, load_address, offset=0, sz=nil, flags=nil,
                arch_info=nil)
      sz ||= image.size
      check_map_overlap(load_address, sz)
      m = Bgo::Map.new(load_address, image, offset, sz, flags, arch_info)
      @arch_info ||= m.arch_info
      add_map_object m
    end

=begin rdoc
Define a Map object for Image at the specified load_address in the Process. If
this overlaps with an existing Map, the next available contiguous sequence of
bytes that can contain the Map is used.
If the Map has been relocated by this method, it will have the
:needs_relocation tag set.
=end
    def add_map_reloc(image, load_address, offset=0, sz=nil, flags=nil,
                      arch_info=nil) 
      sz ||= image.size
      begin
        check_map_overlap(load_address, sz)
      rescue MapOverlapError
        load_address = find_next_free_space(load_address, sz)
      end
      m = add_map image, load_address, offset, sz, flags, arch_info
      if m.vma != load_address
        m.tag(:needs_relocation)
        m.properties[:orig_vma] = load_address
      end
      m
    end

=begin rdoc
Remove Map object for vma in Process.
Note: vma is Map#start_addr, not any address in Map.
=end

    def remove_map(vma)
      @maps.delete vma
    end

=begin rdoc
Move a Map from old_vma to new_vma. Not advisable except with empty Maps
(i.e. no Addresses).
=end
    def rebase_map(old_vma, new_vma)
      m = @maps[old_vma]
      raise("VMA %X not found!" % [old_vma]) if ! m
      check_map_overlap(new_vma, m.size)
      m.vma = new_vma
      @maps[new_vma] = m
      remove_map(old_vma)
    end

=begin rdoc
Return Map object containing VMA.
=end
    def map_containing(vma)
      maps.select { |m| m.contains? vma }.first
    end

=begin rdoc
Return array of maps spanning memory range.
=end
    def maps_for_range(range)
      last = (range.exclude_end?) ? range.last : range.last + 1
      maps.select { |m| m.start_addr >= range.first and m.max < last }
    end

=begin rdoc
Re-implementation of TargetObject#address_containers.
Note that this wraps Process#maps instead of aliasing it, so that the maps()
method will be called by subclasses such as Git::Map.
=end
    def address_containers(ident_only=false, &block)
      maps(ident_only, &block)
    end

=begin rdoc
Re-implementation of TargetObject#address_container.
Note that this wraps Process#map instead of aliasing it, so that the map()
method will be called by subclasses such as Git::Map.
=end
    def address_container(ident)
      map(ident)
    end

=begin rdoc
Return Address object for VMA, if it exists.
This is a convenience routine that finds the map containing VMA, then invokes 
its address() method.
=end
    def address(vma, revision=nil)
      m = map_containing(vma)
      m ? m.address(vma, revision) : nil
    end

    def min_addr
      maps.map { |m| m.start_addr  }.min || 0
    end

    def max_addr
      maps.map { |m| m.max  }.max || 0
    end
=begin rdoc
Iterate over Address objects defined in Process.
This just calls Map#addresses for every map.
=end
    def addresses(rev=nil, &block)
      return to_enum(:addresses, rev) if ! block_given?
      maps.each { |m| m.addresses(rev).each { |a| yield a } }
    end

# ----------------------------------------------------------------------
=begin rdoc
Create a VirtualImage. 
This attempts to invoke the same method in Project if @parent_obj is set. 
It is included in Process for convenience.
=end
    def add_virtual_image(fill, sz)
      return @parent_obj.add_virtual_image(fill, sz) if @parent_obj and \
             (@parent_obj.respond_to? :add_virtual_image)
      img = Bgo::VirtualImage.new(fill, sz)
      img.modelitem_init_parent self
      img
    end
    
# ----------------------------------------------------------------------
=begin rdoc
Load the specified file using a plugin supporting the LOAD_FILE interface.

If no plugin is specified, the plugin with the highest confidence is used.
Note: This will raise a NameError if the PluginManager service is not started.
=end
    def load!(file, plugin=nil, opts={})
      args = :load_file, self, file, opts

      if plugin                                                                 
        plugin = Application::PluginManager.find(plugin) if \
                 (plugin.kind_of? String)
        $stderr.puts "#{plugin.inspect} not found" if ! plugin
      else
        plugin = Application::PluginManager.fittest_providing(*args)
      end
            
      if ! plugin
        $stderr.puts "No :load_file plugins available"
        return false 
      end

      h = plugin.spec_invoke(*args)
      h && (! h.empty?)
    end

# ----------------------------------------------------------------------
    def to_s
      "Process #{ident}"
    end

    def inspect
      str = "Process #{ident}: `#{command}`"
      ai = arch_info
      str << " [#{ai.inspect}]" if ai
      str
    end

    def to_core_hash
      { :ident => ident,
        :command => command,
        :filename => filename,
        :arch_info => (arch_info ? arch_info.to_hash : nil),
      }.merge( to_modelitem_hash )
    end

    def to_hash
      to_core_hash.merge(to_target_hash).merge( { :maps => maps.to_a } )
    end
    alias :to_h :to_hash

    def fill_from_hash(h, proj=nil)
      fill_from_modelitem_hash h
      fill_from_target_hash h

      @arch_info = Bgo::ArchInfo.from_hash h[:arch_info] if h[:arch_info]
      (h[:maps] || []).each do |m|
        hh = m.to_hash
        img = self.class.image_from_hash!(hh, proj)
        flags = (hh[:flags] || []).map { |f| f.to_sym }
        ai = hh[:arch_info] ? ArchInfo.from_hash(hh[:arch_info]) : nil
        add_map(img, hh[:start_addr].to_i, hh[:image_offset].to_i, 
                hh[:size].to_i, flags, ai).fill_from_hash(hh)
      end
      self
    end

    def self.from_hash(h, proj=nil)
      obj = self.new(h[:ident].to_i, h[:command].to_s, h[:filename])
      obj.fill_from_hash h, proj
    end

    protected

    def check_map_overlap(vma, sz)
      @maps.values.each do |m| 
        if (m.overlap? vma, sz)
          raise MapOverlapError.new("%X (%d bytes) overlaps Map at %X (%d)" % 
                                    [vma, sz, m.start_addr, m.size])
        end
      end
    end

    def find_next_free_space(vma, sz)
      last_vma = nil
      @maps.values.each do |m|
        next if m.vma < vma
        break if last_vma && (m.vma - last_vma >= sz) 
        last_vma = m.vma + m.size
      end
      last_vma || vma
    end

    def add_map_object(obj)
      if (obj && (! @maps.include? obj.start_addr))
        obj.modelitem_init_parent self
        target_init_ac obj
        @maps[obj.start_addr] = obj
      end
      obj
    end

    def instantiate_child_from_ident(sym, ident)
      super sym, (sym == :map ? Integer(ident) : ident)
    end 

  end

end
