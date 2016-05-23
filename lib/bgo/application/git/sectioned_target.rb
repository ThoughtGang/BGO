#!/usr/bin/env ruby
# :title: Bgo::Git::SectionedTarget
=begin rdoc
BGO SectionedTarget module in Git-DB.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end  

require 'bgo/sectioned_target'

require 'bgo/application/git/section'

module Bgo
  module Git

    module SectionedTargetObject
      DIR_SEC = 'section'

      def initialize_git_sectioned_target
        @init_sections = false
      end

      def create_sectioned_target_in_repo(repo, repo_path)
        repo.chdir { create_dir_for_modelitem(File.join(repo_path, DIR_SEC)) }
      end

      def update_sectioned_target(&block)
        @sections.each { |k, s| s.update } if children_dirty?
      end

      # ----------------------------------------------------------------------

      def ident_info=(ident); dirty!; super; end

      def parse!(plugin=nil, opts={}); super && dirty! || nil; end

      # ----------------------------------------------------------------------
      def sections(ident_only=false, &block)
        return super if @init_sections
        return to_enum(:sections, ident_only) if ! block_given?

        repo.chdir do
          Dir.glob(child_repo_path(File.join(DIR_SEC, '*'))).each do |f|
            ident = File.basename(f)
            yield ident_only ? ident : section(ident)
          end
        end
        @init_sections = true
      end

      def section(ident)
        return super(ident) if @sections[ident]
        s = Git::Section.load repo, section_path(ident), root
        add_section_object s
      end

      def add_section(ident, file_off=0, sec_size=nil, name=nil, 
                      flags=DEFAULT_FLAGS, arch_info=nil)

        sec_size ||= self.size - offset
        s = Git::Section.create( repo, child_repo_path(DIR_SEC), ident, 
                                 name, image, image_offset + file_off, 
                                 file_off, sec_size, flags )
        s.arch_info = arch_info if arch_info
        children_dirty!
        add_section_object s
      end

      def remove_section(ident)
        Git::Section.delete repo, child_repo_path(DIR_SEC), ident
        children_dirty!
        super
      end

      # ----------------------------------------------------------------------
      protected

      def add_section_object(obj)
        obj.gititem_init_parent self
        super
      end

      def section_path(ident); child_repo_path(File.join(DIR_SEC, ident)); end
    end

  end
end
