#!/usr/bin/env ruby
# Utility to test methods that modify a project.
# Copyright 2010 Thoughtgang <http://www.thoughtgang.org>

require 'bgo/git/project'
require 'bgo/git/file'

def modify_project(proj)

=begin
  f = proj.files.first
  return if not f

  puts "SECTIONS FOR #{f.name}"
  sec = f.sections.reject{ |s| s.name != '.data' }.first
  puts sec.inspect


  a1 = sec.address( 0 )
  #a1.contents = Bgo::Instruction.new
  puts a1.inspect
  a2 = sec.address( 4 )
  puts a2.inspect
  #sec.add_address( 0, 4 )
  #sec.add_address( 4, 2 )
  #sec.add_address( 6, 2 )
  #sec.add_address( 8, 8 )

  #puts sec.addresses.inspect

  #proj.save( 'Target comment added', 'Basic Project Test Script' )
=end

  return true
end

def open_project(path)
  proj = Bgo::Git::Project.new(path)
  puts "NAME: " + proj.name
  puts "DESCR: " + proj.description
  puts "CREATED: " + proj.created.to_s
  puts "BGO VERSION: " + proj.bgo_version.to_s
  
  puts "IMAGES: " + proj.images.inspect
  puts "FILES: " + proj.files.inspect
  puts "PROCESSES:" + proj.processes.inspect

  proj
end

def display_project(proj)
  puts 'BRANCHES'
  puts proj.repo.branches.inspect
  puts 'TAGS'
  puts proj.repo.tags.inspect

  #t = proj.repo.tags.first
  #puts t.inspect
  # How to add a tag:
  #tag = Grit::Tag.new( 'AnotherTag', sha )
  #proj.repo.git.fs_write( "refs/tags/#{tag.name}", sha )
  #puts proj.repo.tags.inspect
end

if __FILE__ == $0
  if ARGV.count == 0 
    puts "Usage: #{$0} path"
    exit 1
  end

  proj = open_project(ARGV[0])

  modify_project(proj)

  display_project(proj)
end
