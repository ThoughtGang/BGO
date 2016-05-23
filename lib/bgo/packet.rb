#!/usr/bin/env ruby                                                             
# :title: Bgo::Packet
=begin rdoc
==BGO Packet object
<i>Copyright 2013 Thoughtgang <http://www.thoughtgang.org></i>

A Packet is a contiguous range of bytes from an Image object. It can be
divided into Section objects, like a TargetFile, but it cannot be loaded into
a Process object.
=end  

require 'bgo/arch_info'
require 'bgo/image'
require 'bgo/ident'
require 'bgo/model_item'
require 'bgo/target'
require 'bgo/sectioned_target'

module Bgo

=begin rdoc
A contiguous sequence of bytes which is not mapped into memory, but which can
be analyzed as a Target. This is generally used to model network packet data,
and the default architecture information is therefore the Network Architecture
(big-endian).

A Packet can have one or more Sections, like a file. The use of Sections allows
the various components of the Packet (e.g. IP header, TCP header, protocol
header) to be treated as distinct entities, and provides a way to change the
architecture for regions of the packet (e.g. an executable payload).
=end
  class Packet
    extend Bgo::ModelItemClass
    include Bgo::ModelItemObject
    include Bgo::TargetObject
    include Bgo::SectionedTargetObject

=begin rdoc
Name of the Packet. This is an arbitrary string provided by the user.
=end
    attr_reader :ident

    def self.path_elem
      'packet'
    end

    def self.dependencies
      [ Bgo::Image ]
    end

    def self.child_iterators
      [:sections]
    end

    def self.default_child
      :section
    end

=begin rdoc
Instantiate a Packet object for an Image object with the given ident.
=end
    def initialize(ident, img, img_offset=nil, sz=nil )
      sz ||= img.size
      modelitem_init
      target_init
      sectioned_target_init img, img_offset, sz
    end

=begin rdoc
Add a Section object to Packet.
If ArchInfo is not provided, it will be set to NetworkArchInfo.new
=end
    def add_section(s_ident, off=0, sz=nil, name=nil, 
                    flgs=Section::DEFAULT_FLAGS, arch_info=nil)
      arch_info ||= NetworkArchInfo.new
      super
    end

# ----------------------------------------------------------------------
    def to_s
      "File '#{ident}'"
    end

    def inspect
      str = "Packet '#{ident}' { Image #{image.ident} }"
      str
    end

# ----------------------------------------------------------------------
    def to_core_hash
      {
        :ident => ident
      }.merge( to_modelitem_hash ).merge( to_sectioned_target_core_hash )
    end

    def to_hash
      to_core_hash.merge(to_target_hash).merge(to_sectioned_target_hash)
    end
    alias :to_h :to_hash

    def fill_from_hash(h, proj=nil)
      fill_from_modelitem_hash h
      fill_from_target_hash h
      fill_from_sectioned_target_hash h

      @ident_info = Bgo::Ident.from_hash(h[:ident_info]) if h[:ident_info]
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
      obj = self.new(h[:ident].to_s, img, h[:image_offset].to_i, h[:size].to_i)
      obj.fill_from_hash h, proj
      obj
    end

    # ----------------------------------------------------------------------
    protected

  end

end
