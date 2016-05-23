#!/usr/bin/env ruby
# Utility to test the creation of a project and the addition of one or more
# files. The files are parsed and loaded by the most suitable plugin.
# Copyright 2010 Thoughtgang <http://www.thoughtgang.org>

require 'bgo/git/project'
require 'bgo/git/file'
require 'bgo/plugin_mgr'

SCRIPT_ACTOR = Grit::Actor.new('Basic Project Test Script', 
                                Bgo::Git::BGO_ACTOR_EMAIL)

def add_target(proj, target)
  f = proj.add_file( target )

  f.comment = "User loaded #{target} via basic_project test script."
  proj.commit( 'Target comment added', SCRIPT_ACTOR )

  # parse target
  f.parse!
  proj.commit( "#{target} parsed", SCRIPT_ACTOR )

  p = proj.add_process( "#{target} --test", f.name, nil, 'Exec w/ --test' )

  # load target
  p.load!(f)
  proj.commit( "#{target} loaded", SCRIPT_ACTOR )

  # Print details
  puts "-------------"
  puts "Target name: #{f.name}"
  puts "Target path: #{f.path}"
  puts "Target image: #{f.image}"
  puts "Target comment: #{f.comment}"

  puts "PROJECT CONTENTS:"
  puts proj.files
  puts proj.images
  puts proj.processes
end

def make_repo(path)
  proj = Bgo::Git::Project.new(path)

  proj.name = 'Basic'
  proj.description = 'A Basic BGO Project, for testing.'

  puts "NAME: " + proj.name
  puts "DESCR: " + proj.description
  puts "CREATED: " + proj.created.to_s
  puts "BGO VERSION: " + proj.bgo_version.to_s

  proj.commit( 'Project created.', SCRIPT_ACTOR )

  proj
end

if __FILE__ == $0
  if ARGV.count == 0 
    puts "Usage: #{$0} PATH [FILE] [...]"
    exit 1
  end

  proj = make_repo(ARGV.shift)

  Bgo::PluginManager.load_all()

  while !(ARGV.empty?)
    fname = ARGV.shift
    next if not (::File.exist? fname)

    tag = proj.repo.clean_tag(::File.basename(fname))

    # Load target in new branch
    proj.save( "LoadFile_#{tag}", SCRIPT_ACTOR ) do |opts|
      opts[:name] = tag
      opts[:msg] = "Load file '#{fname}' using default plugins"

      add_target( proj, fname )
    end

  end
end
