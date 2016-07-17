#!/usr/bin/env ruby
# :title: Javaclass Plugin
=begin rdoc
BGO Javaclass loader plugin

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

NOTE: This requires the javaclass gem. See http://code.google.com/p/javaclass-rb
=end

require 'bgo/application/plugin'

require 'bgo/file'
require 'bgo/file_format'
require 'bgo/map'
require 'bgo/section'

require 'rubygems'
require 'javaclass'

module Bgo
  module Plugins
    module Parser

=begin rdoc
Plugin for using the Javaclass gem inside BGO.
=end
      class Javaclass
        extend Bgo::Plugin

        Bgo::FileFormat.supports 'Java Class'

        # ----------------------------------------------------------------------
        # DESCRIPTION

        name 'javaclass'
        author 'dev@thoughtgang.org'
        version '1.0'
        description 'Load Java class files'
        help 'Java Class File Parser
Requires the \'javaclass\' gem. See http://code.google.com/p/javaclass-rb
'

        # ----------------------------------------------------------------------
        # SPECIFICATIONS

        spec :ident, :identify, 10 do |buf, path|
          decode_header(buf, path) ? 75 : 0
        end

        spec :parse_file, :parse, 10 do |file, hash|
          next 90 if file.property(:ident_plugin) == canon_name
          decode_header(file.contents) ? 75 : 0
        end

        spec :load_file, :load, 10 do |process, file, hash|
          next 90 if file.property(:ident_plugin) == canon_name
          decode_header(file.contents) ? 75 : 0
        end

        # ----------------------------------------------------------------------
        # API

        api_doc :identify, ['String', 'String'], 'Ident', \
                'identify contents of a vinary String using Metasm::AutoExe'
        def identify(buf, path='')
          hdr = decode_header(buf, path)
          # TODO: support jar!

          fmt = 'Java class'
          #arch = 'jvm'

          # TODO: if has-main?
          mime = Bgo::Ident::MIME_EXECUTABLE
          #Bgo::Ident::MIME_OBJFILE
          #Bgo::Ident::MIME_SHAREDLIB
          #Bgo::Ident::MIME_COREDUMP
          #Bgo::Ident::MIME_ARCHIVE

          summary = "JVM #{hdr.version.jdk_version} class"
          full = "Version %s JVM Version %s Flags %s" % [hdr.version.to_s,
                  hdr.version.jdk_version, decode_flags(hdr.access_flags.flags)]

          Bgo::Ident.new Bgo::Ident::CONTENTS_CODE, summary, full, mime, fmt
        end

        # =================================================================
        api_doc :parse, ['TargetFile|Packet', 'Hash'], 'Hash', \
                'Parse TargetFile using Metasm'
        def parse(tgt, opts={})
          return if not tgt.kind_of? Bgo::SectionedTargetObject

          hdr = decode_header(tgt.contents)
          return {} if ! hdr

          output = { :sections => [], :symbols => [] }

          # TODO: create section for each class?
          # hdr.constant_pool.strings
          hdr.constant_pool.items.each do |c|
            if c.const_class?
              #$stderr.puts 'Class ' + c.class_name
            elsif c.const_field?
              #$stderr.puts 'Field ' + c.class_name
            elsif c.const_method?
              #$stderr.puts 'Method ' + c.class_name
            elsif c.kind_of? ::JavaClass::ClassFile::Constants::ConstantAsciz
              #$stderr.puts 'ASCIZ ' + c.value
            elsif c.kind_of? ::JavaClass::ClassFile::Constants::ConstantNameAndType
              #$stderr.puts 'NameAndType ' + c.to_s
            elsif c.kind_of? ::JavaClass::ClassFile::Constants::ConstantString
              #$stderr.puts 'String ' + c.first_value
            else
              #$stderr.puts 'Unknown constant: ' + c.class.name
            end
          end

          output
        end

        # =================================================================
        api_doc :load, ['Process', 'TargetFile', 'Hash'], 'Hash', \
                'Load TargetFile into Process using Metasm'
        def load(process, file, opts={})
          return if not process.kind_of? Bgo::Process
          return if not file.kind_of? Bgo::SectionedTargetObject

          hdr = decode_header(file.contents)
          return {} if ! hdr

          output = { :arch_info => nil, :maps => [], :images => [], 
                     :symbols => [] }

          # TODO: create map for each class?

          output
        end

        # =================================================================

        def decode_header(buf, path='')
          begin
            if buf && (! buf.empty?)
              ::JavaClass.disassemble( buf )
            elsif (path && ! path.empty?)
              ::JavaClass.load_fs(path) 
            end
          rescue ::JavaClass::ClassFile::ClassFormatError
            nil
          end
        end

        def decode_flags(num)
          flags = []
          flags << 'PUBLIC' if num & 0x0001
          flags << 'FINAL' if num & 0x0010
          flags << 'SUPER' if num & 0x0020
          flags << 'INTERFACE' if num & 0x0200
          flags << 'ABSTRACT' if num & 0x0400
          flags << 'SYNTHETIC' if num & 0x1000
          flags << 'ANNOTATION' if num & 0x2000
          flags << 'ENUM' if num & 0x4000
          flags
        end

        def mime_from_header(hdr)
          obj_type = nil
          obj_type = hdr.type if hdr.respond_to? :type
          obj_type ||= hdr.filetype if hdr.respond_to? :filetype
          obj_type ||= hdr.characteristics.join(' ') if \
                       hdr.respond_to? :characteristics

        end

=begin rdoc
        def add_section(tgt, sec, ai)
          flags = [ Map::FLAG_READ ]

          flags << Map::FLAG_WRITE if sec.flags.include? 'WRITE'
          flags << Map::FLAG_EXEC if (sec.flags.include? 'EXECINSTR') ||
                                     (sec.flags.include? 'CODE')
          # Create Section object for this file section
          s = tgt.add_section(sec[:ident], sec[:offset], sec[:file_size], 
                              sec[:name], sec[:flags], ai)

          # store original metadata in properties
          s.properties[:header_flags] = sec[:raw_flags] if sec[:raw_flags]
          s.properties[:header_type] = sec[:raw_type] if sec[:raw_type]
          s.properties[:header_info] = sec[:raw_info] if sec[:raw_info]
          s
            :flags => [Map::FLAG_READ, Map::FLAG_WRITE, Map::FLAG_EXEC]
        end
=end

=begin rdoc
Map a segment Hash into Process memory.
        def map_segment(p, img, m_obj, seg, ai) 
          # TODO: if filesz and memsz differ
          # TODO: .BSS
          m = p.add_map_reloc( img, seg[:vma], seg[:offset], seg[:file_size], 
                               seg[:flags], ai)
          # TODO: if m.tags[:needs_relocation]

          # store original metadata in properties
          m.properties[:header_flags] = seg[:raw_flags] if seg[:raw_flags]
          m.properties[:header_type] = seg[:raw_type] if seg[:raw_type]
          m.properties[:header_info] = seg[:raw_info] if seg[:raw_info]
          m
        end
=end

      end

    end
  end
end

__END__
 puts clazz.version                          # => "50.0"
 puts clazz.constant_pool.items[1]           # => "packagename/AccessFlagsTestPublic"
 puts clazz.access_flags.public?             # => true
 puts clazz.access_flags.final?              # => false
 puts clazz.this_class                       # => "packagename/AccessFlagsTestPublic"
 puts clazz.super_class                      # => "java/lang/Object"
 puts clazz.super_class.to_classname         # => "java.lang.Object"
 puts clazz.references.referenced_methods[0] # => "java/lang/Object.<init>:()V"
 puts clazz.interfaces                       # => []

Returned class names are not just Strings, but JavaClass::JavaQualifiedName

 puts clazz.this_class.to_java_file          # => "packagename/AccessFlagsTestPublic.java"
 puts clazz.this_class.full_name             # => "packagename.AccessFlagsTestPublic"
 puts clazz.this_class.package               # => "packagename"
 puts clazz.this_class.simple_name           # => "AccessFlagsTestPublic"
 clazz.to_javaname 
 clazz.to_jvmname 
 clazz.this_class

 # load eclipse project:
 require 'javaclass/classpath/factory'
 location = 'C:\Eclipse\workspace'
 cp = workspace(location)
  puts "library (module path): number of contained classes"
 puts cp.elements.map { |clp| [clp.to_s, clp.count] }.
                  sort { |a,b| a[1] <=> b[1] }.
                  map { |e| "  #{e[0]}: #{e[1]}" }
