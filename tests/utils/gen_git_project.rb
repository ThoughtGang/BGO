#!/usr/bin/env ruby
# Copyright 2011 Thoughtgang <http://www.thoughtgang.org>
# Generate a specific BGO project for Git unit tests

require 'fileutils'

$: << 'lib'
require 'bgo/git/project'

DATA_DIR = 'tests/targets'
PROJ_NAME = 'git-test.bgo'
FILE_NAME = 'linux-2.6.x-64.bin'

if __FILE__ == $0
  puts "OK BUILDING PROJECT IN #{Dir.pwd}"
  raise "Missing target dir #{DATA_DIR}" if not ::File.exist?(DATA_DIR)

  dir = DATA_DIR + ::File::SEPARATOR
  path = dir + PROJ_NAME
  FileUtils.remove_dir(path) if ::File.exist?(path)

  proj = Bgo::Git::Project.new(path)
  raise "Unable to create project #{path}" if not proj

  path = dir + FILE_NAME
  raise "Missing file #{path}" if not ::File.exist?(path)

  f = proj.add_file(path)
  raise "Unable to add file #{path} to project" if not f
end

