#!/usr/bin/env ruby

require 'bgo/git'

path = File.join('tests', 'repos', 'bfd.bgo')
proj = Bgo::Git::Project.open(path)
                
puts proj.inspect

puts
puts "ModelItem Classes:"
puts Bgo::Git::MODEL_ITEM_CLASSES.inspect
puts
puts "ModelItem Class names:"
Bgo::Git::MODEL_ITEM_CLASSES.each { |cls| puts cls.name }

puts
puts Bgo::Git::factory(proj, 'process').inspect
puts Bgo::Git::factory(proj, 'process/1000/map/400000').inspect
puts Bgo::Git::factory(proj, 'process/1000/map/400000/comment').inspect
puts Bgo::Git::factory(proj, 'process/1000/map/400000/changeset/0').inspect
puts Bgo::Git::factory(proj, 'process/1000/map/400000/changeset/0/address').inspect
