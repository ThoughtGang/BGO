#!/usr/bin/env ruby
# :title: Bgo XML support
=begin rdoc
XML Support

Copyright 2011 Thoughtgang <http://www.thoughtgang.org>

Methods to add XML support to the BGO data model.

!!!!!! OBSOLETE !!!!!!!
=end

raise "#{__FILE__} : NOT IMPLEMENTED"

require 'rexml/document'

# ensure all data model classes are loaded
require 'bgo/address'
require 'bgo/arch_info'
require 'bgo/changeset'
require 'bgo/file'
require 'bgo/ident'
require 'bgo/image'
require 'bgo/instruction'
require 'bgo/map'
require 'bgo/process'
require 'bgo/project'
require 'bgo/reference'
require 'bgo/section'
require 'bgo/symbol'

module Bgo

  # ----------------------------------------------------------------------
  class Address

    XML_VMA_ELEM='vma'
    XML_OFFSET_ELEM='offset'
    XML_SIZE_ELEM='size'
    XML_IMAGE_ELEM='image'
    XML_BYTES_ELEM='bytes'
    XML_CMT_ELEM='comment'
    XML_CONTENTS_ELEM='contents'

    def to_xml
      root = REXML::Element.new(self.class.name.split('::').last)

      root.add_attribute( XML_VMA_ELEM, "%d" % self.size )
      root.add_attribute( XML_OFFSET_ELEM, "%X" % self.offset )
      root.add_attribute( XML_SIZE_ELEM, "%X" % self.vma )
      root.add_attribute( XML_IMAGE_ELEM, self.image.ident )

      el = root.add_element( XML_BYTES_ELEM )
      el.add_text( self.bytes.map{ |x| "%02X" % x }.join(' ') ) if self.bytes

      el = root.add_element( XML_CONTENTS_ELEM )
      if contents.respond_to? :to_xml
        el.add_element(contents.to_xml)
      else
        el.add_text(contents.to_s)
      end

      el = root.add_element( XML_CMT_ELEM )
      el.add_text(comment) if comment && (! comment.empty?)

      root
    end

    def self.from_xml(root)
      return if not root
      @root_items.each do |item|
      #  TODO!
      #  item.from_xml( root )
      end
    end
    
  end

  class ArchInfo
    XML_ARCH_ELEM='architecture'
    XML_MACH_ELEM='machine'
    XML_ENDIAN_ELEM='endian'

    def to_xml
      root = REXML::Element.new(self.class.name.split('::').last)

      el = root.add_element(XML_ARCH_ELEM)
      el.add_text(self.arch.to_s)

      el = root.add_element(XML_MACH_ELEM)
      el.add_element(self.mach.to_s)

      el = root.add_element(XML_ENDIAN_ELEM)
      el.add_element(self.endian.to_s)

      root
    end

    def self.from_xml(root)
      return if not root
      @root_items.each do |item|
      #  TODO!
      #  item.from_xml( root )
      end
    end
    
  end

  # ----------------------------------------------------------------------
  class Changeset
    XML_IDENT_ELEM='ident'
    XML_ADDRS_ELEM='addresses'
    XML_BYTES_ELEM='changes'
    XML_BYTE_ELEM='byte'
    XML_VMA_ELEM='vma'
    XML_VAL_ELEM='value'
    XML_CMT_ELEM='comment'

    def to_xml
      root = REXML::Element.new(self.class.name.split('::').last)

      el = root.add_attribute(XML_IDENT_ELEM,self.ident)

      el = root.add_element(XML_ADDRS_ELEM)
      addresses.each { |a| el.add_element(a.to_xml) }

      el = root.add_element(XML_BYTES_ELEM)
      changed_bytes.each do |vma, val|
        b_el = el.add_element(XML_BYTE_ELEM)
        b_el.add_attribute(XML_VMA_ELEM, "%X" % vma)
        b_el.add_attribute(XML_VAL_ELEM, "%X" % val)
      end

      el = root.add_element(XML_CMT_ELEM)
      el.add_element(comment) if comment && (! comment.empty?)

      root
    end

    def self.from_xml(root)
      return if not root
      @root_items.each do |item|
      #  TODO!
      #  item.from_xml( root )
      end
    end
  end

  # ----------------------------------------------------------------------
  class Ident

    XML_TYPE_ELEM='content-type'
    XML_MIME_ELEM='mime-typw'
    XML_FMT_ELEM='file format'
    XML_SUM_ELEM='summary'
    XML_FULL_ELEM='full'

    def to_xml
      root = REXML::Element.new(self.class.name.split('::').last)

      el = root.add_element(XML_TYPE_ELEM)
      el.add_text(self.contents.to_s)

      el = root.add_element(XML_MIME_ELEM)
      el.add_element(self.mime) if self.mime

      el = root.add_element(XML_FMT_ELEM)
      el.add_element(self.format) if self.format

      el = root.add_element(XML_SUM_ELEM)
      el.add_text(self.summary)

      el = root.add_element(XML_FULL_ELEM)
      el.add_element(self.full)

      root
    end

    def self.from_xml(root)
      return if not root
      @root_items.each do |item|
      #  TODO!
      #  item.from_xml( root )
      end
    end
    
  end

  # ----------------------------------------------------------------------
  class TargetFile

    XML_IDENT_ELEM='ident'
    XML_NAME_ELEM='name'
    XML_DIR_ELEM='dir'
    XML_PATH_ELEM='path'
    XML_IMAGE_ELEM='image'
    XML_OFFSET_ELEM='offset'
    XML_SIZE_ELEM='size'
    XML_IDENT_INFO_ELEM='ident_info'
    XML_CMT_ELEM='comment'
    XML_FILES_ELEM='files'
    XML_SECTIONS_ELEM='sections'

    def to_xml
      root = REXML::Element.new(self.class.name.split('::').last)

      el = root.add_attribute(XML_NAME_ELEM, self.name)
      el = root.add_attribute(XML_DIR_ELEM, self.dir)
      el = root.add_attribute(XML_PATH_ELEM, self.full_path)
      el = root.add_attribute(XML_IDENT_ELEM, self.ident)
      el = root.add_attribute(XML_IMAGE_ELEM, self.image.ident)
      el = root.add_attribute(XML_OFFSET_ELEM, "0x%X" % self.offset)
      el = root.add_attribute(XML_SIZE_ELEM, "0x%X" % self.size)

      el = root.add_element(XML_FILES_ELEM)
      self.files.each { |f| el.add_element(f.to_xml) }

      el = root.add_element(XML_SECTIONS_ELEM)
      self.sections.each { |s| el.add_element(s.to_xml) }

      el = root.add_element(XML_IDENT_INFO_ELEM)
      el.add_text(self.ident_info.to_xml) if self.ident_info

      el = root.add_element(XML_CMT_ELEM)
      el.add_element(comment) if comment && (! comment.empty?)

      root
    end

    def self.from_xml(root)
      return if not root
      @root_items.each do |item|
      #  TODO!
      #  item.from_xml( root )
      end
    end

  end

  # ----------------------------------------------------------------------
  class Image 
    XML_IDENT_ELEM='ident'
    XML_CMT_ELEM='comment'
    XML_CONTENTS_ELEM='contents'

    def to_xml
      root = REXML::Element.new(self.class.name.split('::').last)

      el = root.add_attribute(XML_IDENT_ELEM, self.ident.to_s)

      el = root.add_element(XML_CONTENTS_ELEM)
      el.add_element(Base64.encode64(self.contents))

      el = root.add_element(XML_CMT_ELEM)
      el.add_element(comment) if comment && (! comment.empty?)

      root
    end

    def self.from_xml(root)
      return if not root
      @root_items.each do |item|
      #  TODO!
      #  item.from_xml( root )
      end
    end

  end

  # ----------------------------------------------------------------------
  class VirtualImage

    XML_SIZE_ELEM='size'
    XML_FILL_ELEM='fill'

    def to_xml
      root = REXML::Element.new(self.class.name.split('::').last)

      el = root.add_element(XML_IDENT_ELEM)
      el.add_text(self.ident.to_s)

      el = root.add_element(XML_SIZE_ELEM)
      el.add_element(Base64.encode64(self.size))

      el = root.add_element(XML_FILL_ELEM)
      el.add_element(Base64.encode64(self.fill))

      el = root.add_element(XML_CMT_ELEM)
      el.add_element(comment) if comment && (! comment.empty?)

      root
    end

    def self.from_xml(root)
      return if not root
      @root_items.each do |item|
      #  TODO!
      #  item.from_xml( root )
      end
    end

  end

  # ----------------------------------------------------------------------
  class Instruction

    def to_xml
      root = REXML::Element.new('Instruction')
      root.add_attribute('ascii', self.ascii)
      root.add_attribute('arch', self.arch)
      root.add_attribute('comment', self.comment)
      el = root.add_element('prefixes')

      self.prefixes.each do |p| 
        prefix = el.add_element('prefix')
        prefix.add_text(p)
      end

      el = root.add_element('side_effects')
      self.side_effects.each do |se| 
        effect = el.add_element('effect')
        effect.add_text(se)
      end

      root.add_element(self.opcode.to_xml)
      root.add_element(self.operands.to_xml)
      root
    end

  end

  # ----------------------------------------------------------------------
  class Opcode

    def to_xml
      root = REXML::Element.new('Opcode')
      root.add_attribute('mnemonic', self.mnemonic)
      root.add_attribute('isa', self.isa)
      root.add_attribute('category', self.category)

      el = root.add_element('operations')
      self.operations.each do |o|
        op = el.add_element('op')
        op.add_text(o.to_s)
      end

      flg = root.add_element('flags')
      el = flg.add_element('tested')
      self.flags_read.each do |f|
        flag = el.add_element('flag')
        flag.add_text(f.to_s)
      end

      el = flg.add_element('set')
      self.flags_set.each do |f|
        flag = el.add_element('flag')
        flag.add_text(f.to_s)
      end
      root
    end

  end

  # ----------------------------------------------------------------------
  class OperandList

    def to_xml
      root = REXML::Element.new('Operands')
      self.each_with_index do |op, idx|
        el = op.to_xml
        name = operand_name(idx)
        el.add_attribute('name', name) if name
        root.add_element(el)
      end
      root
    end

  end

  # ----------------------------------------------------------------------
  class Operand

    def to_xml
      root = REXML::Element.new('Operand')
      root.add_attribute('ascii', self.ascii)
      root.add_attribute('access', self.access)

      el = root.add_element('value')
      if value.respond_to? :to_xml
        el.add_element(value.to_xml)
      else
        el.add_text(value.to_s)
      end

      root
    end

  end

  # ----------------------------------------------------------------------
  class Register

    def to_xml
      root = REXML::Element.new('Register')

      root.add_attribute('mnemonic', self.mnemonic)
      root.add_attribute('id', self.id)
      root.add_attribute('mask', self.mask)
      root.add_attribute('size', self.size)
      root.add_attribute('type', self.type.to_s)

      el = root.add_element('purposes')
      self.purpose.each do |p|
        purpose = el.add_element('purpose')
        purpose.add_text(p.to_s)
      end

      root
    end

  end

  # ----------------------------------------------------------------------
  class IndirectAddress

    def to_xml
      root = REXML::Element.new('IndirectAddress')
      el = root.add_element('scale')
      el.add_text(self.scale.to_s)

      el = root.add_element('index')
      el.add_element(self.index.to_xml) if self.index

      el = root.add_element('base')
      el.add_element(self.base.to_xml) if self.base

      el = root.add_element('displacement')
      el.add_text(self.displacement.to_s) if self.displacement

      el = root.add_element('segment')
      el.add_element(self.segment.to_xml) if self.segment

      root
    end

    def self.from_xml(root)
      return if not root
      @root_items.each do |item|
      #  TODO!
      #  item.from_xml( root )
      end
    end
    
  end

  # ----------------------------------------------------------------------
  class Map

    XML_START_ELEM='start vma'
    XML_IMAGE_ELEM='image'
    XML_OFFSET_ELEM='image offset'
    XML_SIZE_ELEM='size'
    XML_FLAGS_ELEM='flags'
    XML_CMT_ELEM='comment'
    XML_CS_ELEM='changesets'

    def to_xml
      root = REXML::Element.new(self.class.name.split('::').last)

      el = root.add_attribute(XML_START_ELEM, "0x%X" % self.start_addr)
      el = root.add_attribute(XML_IMAGE_ELEM, self.image.ident.to_s)
      el = root.add_attribute(XML_OFFSET_ELEM, "0x%X" % self.offset)
      el = root.add_attribute(XML_SIZE_ELEM, "0x%X" % self.size)

      el = root.add_element(XML_FLAGS_ELEM)
      flags.each { |f| el.add_attribute(f, true) }

      el = root.add_element(self.arch_info.to_xml) if self.arch_info

      el = root.add_element(XML_CS_ELEM)
      changesets.each { |cs| el.add_element(cs.to_xml) }

      el = root.add_element(XML_CMT_ELEM)
      el.add_element(comment) if comment && (! comment.empty?)

      root
    end

    def self.from_xml(root)
      return if not root
      @root_items.each do |item|
      #  TODO!
      #  item.from_xml( root )
      end
    end

  end

  # ----------------------------------------------------------------------
  class Process

    XML_IDENT_ELEM='ident'
    XML_CMD_ELEM='command'
    XML_FILE_ELEM='file'
    XML_MAPS_ELEM='maps'
    XML_ARCH_INFO_ELEM='arch_info'
    XML_CMT_ELEM='comment'

    def to_xml
      root = REXML::Element.new(self.class.name.split('::').last)

      el = root.add_attribute(XML_IDENT_ELEM, self.ident.to_s)
      # TODO: fix to file ref to be file.ident
      el = root.add_attribute(XML_FILE_ELEM, self.filename.to_s)

      el = root.add_element(XML_CMD_ELEM)
      el.add_text(self.command.to_s)

      el = root.add_element(XML_MAPS_ELEM)
      maps.each { |m| el.add_element(m.to_xml) }

      el = root.add_element(XML_ARCH_INFO_ELEM)
      el.add_text(self.arch_info.to_xml) if self.arch_info

      el = root.add_element(XML_CMT_ELEM)
      el.add_element(comment) if comment && (! comment.empty?)

      root
    end

    def self.from_xml(root)
      return if not root
      @root_items.each do |item|
      #  TODO!
      #  item.from_xml( root )
      end
    end

  end

  # ----------------------------------------------------------------------
  class Project

    XML_NAME_ELEM='name'
    XML_DESC_ELEM='description'
    XML_VER_ELEM='bgo version'
    XML_DATE_ELEM='create date'
    XML_FILES_ELEM='files'
    XML_IMAGES_ELEM='images'
    XML_PROCESSES_ELEM='Processes'

    def to_xml
      root = REXML::Element.new(self.class.name.split('::').last)

      el = root.add_attribute(XML_NAME_ELEM, self.name)
      el = root.add_attribute(XML_DESC_ELEM, self.description.to_s)
      el = root.add_attribute(XML_VER_ELEM, self.bgo_version.to_s)
      el = root.add_attribute(XML_DATE_ELEM, self.created.to_s)

      el = root.add_element(XML_FILES_ELEM)
      files.each { |f| el.add_element(f.to_xml) }

      el = root.add_element(XML_IMAGES_ELEM)
      images.each { |i| el.add_element(i.to_xml) }

      el = root.add_element(XML_PROCESSES_ELEM)
      processes.each { |p| el.add_element(p.to_xml) }

      root
    end

    def self.from_xml(root)
      return if not root
      @root_items.each do |item|
      #  TODO!
      #  item.from_xml( root )
      end
    end

  end

  # ----------------------------------------------------------------------
  # HUGE TODO: REFERENCE NOT IMPLEMENTED YET
  class Reference
    def to_xml
      root = REXML::Element.new('Reference')
      el = root.add_element('from')
      el.add_text(self.from.to_xml)

      el = root.add_element('to')
      el.add_element(self.to.to_xml)

      el = root.add_element('comment')
      el.add_element(comment) if comment && (! comment.empty?)

      root
    end

    def self.from_xml(root)
      return if not root
      @root_items.each do |item|
      #  TODO!
      #  item.from_xml( root )
      end
    end

  end

  # ----------------------------------------------------------------------
  class Section

    XML_IDENT_ELEM='ident'
    XML_NAME_ELEM='name'
    XML_FILE_ELEM='file'
    XML_OFFSET_ELEM='offset'
    XML_SIZE_ELEM='size'
    XML_FLAGS_ELEM='flags'
    XML_ARCH_INFO_ELEM='arch_info'
    XML_CMT_ELEM='comment'

    def to_xml
      root = REXML::Element.new(self.class.name.split('::').last)

      el = root.add_attribute(XML_IDENT_ELEM, self.ident.to_s)
      el = root.add_attribute(XML_NAME_ELEM, self.name)
      # TODO: this is currently not stored in section
      #el = root.add_(XML_FILE_ELEM, self.file.ident)
      el = root.add_attribute(XML_OFFSET_ELEM, "0x%X" % self.offset)

      el = root.add_attribute(XML_SIZE_ELEM, "0x%X" % self.size)

      el = root.add_element(XML_FLAGS_ELEM)
      flags.each do |f|
        el.add_attribute( f, true)
      end

      el = root.add_element(XML_ARCH_INFO_ELEM)
      el.add_element(self.arch_info.to_xml) if self.arch_info

      el = root.add_element(XML_CMT_ELEM)
      el.add_element(comment) if comment && (! comment.empty?)

      root
    end

    def self.from_xml(root)
      return if not root
      @root_items.each do |item|
      #  TODO!
      #  item.from_xml( root )
      end
    end

  end

  # ----------------------------------------------------------------------
  class Symbol
    def to_xml
      root = REXML::Element.new('Symbol')
      el = root.add_element('name')
      el.add_text(self.name.to_s)

      el = root.add_element('value')
      el.add_element(self.value.to_xml) if self.value

      el = root.add_element('type')
      el.add_element(self.type)

      el = root.add_element('comment')
      el.add_element(comment) if comment && (!comment.empty?)

      root
    end

    def self.from_xml(root)
      return if not root
      @root_items.each do |item|
      #  TODO!
      #  item.from_xml( root )
      end
    end

  end

end
