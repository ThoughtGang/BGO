#!/usr/bin/env ruby
# :title: BGO Example: Project Processes

require 'bgo/application/git'

# ----------------------------------------------------------------------
def print_object_comments(obj, indent)
  lines = []
  obj.comments.contexts.sort.each do |ctx|
    obj.comments[ctx].each do |author, cmt|
      lines << "  [#{ctx.to_s.upcase}] #{author} #{cmt.ts_str}:"
      lines << "    #{cmt.truncate(80 - indent.length - 4)}"
    end
  end
  return if lines.empty?
  puts "#{indent}Comments:"
  lines.each { |txt| puts "#{indent}#{txt}" }
end

def print_object_properties(obj, indent)
  props = obj.properties
  return if props.empty?
  puts "#{indent}Properties:"
  props.keys.sort.each do |k|
    puts "#{indent}  #{k.to_s} : #{props[k].inspect}"
  end
end

def print_object_tags(obj, indent)
  tags = obj.tags.map { |t| t.to_s }.join ' '
  puts "#{indent}Tags: #{tags}" if (! tags.empty?)
end

def print_object_metadata(obj, indent)
  puts "#{indent}ObjPath: #{obj.obj_path}"
  print_object_tags(obj, indent)
  print_object_comments(obj, indent)
  print_object_properties(obj, indent)
end
# ----------------------------------------------------------------------

def print_addr(addr)
  puts "      Address: #{addr.ident}"
  print_object_metadata(addr, '        ')
  puts "        VMA: %08X" % addr.vma
  puts "        Size: #{addr.size}"
  puts "        Content Type: #{addr.content_type}"
  puts "        Name: #{addr.name}" if addr.name
  if addr.content_type != Bgo::Address::CONTENTS_UNK
    puts '        Contents:'
    puts "          #{addr.contents.inspect}"
  end
end

def print_map(map)
  puts "      Map: #{map.ident}"
  print_object_metadata(map, '      ')
  puts "      Image: #{map.image.ident}"
  puts "      Start VMA: %08X" % map.start_addr
  puts "      End   VMA: %08X" % (map.start_addr + map.size)
  puts "      Flags: #{map.flags.inspect}"
  puts '      Addresses:'
  map.addresses(0).each { |addr| print_addr(addr) }
  map.revisions.reject { |n| n.ident == 0 }.each do |rev|
    puts "      Revision #{n}:"
    map.addresses(n).each { |addr| print_addr(addr) }
  end
end

def print_process(p)
  puts "    Process: #{p.ident}"
  print_object_metadata(p, '    ')
  puts "    Command: `#{p.command}`" if p.command && (! p.command.empty?)
  puts "    ArchInfo: #{p.arch_info}"
  puts "    Maps:"
  p.maps.each { |m| print_map(m); puts '' }
end

def print_project(proj)
  puts "Project: #{proj.name}"

  descr = proj.description
  puts "         #{descr}" if descr && (! descr.empty?)

  print_object_tags(proj, '  ')
  print_object_comments(proj, '  ')

  puts '  Processes:'
  proj.processes.each { |p| print_process(p); puts '' }
end

# ----------------------------------------------------------------------
if __FILE__ == $0
  path = ARGV.shift
  raise "Usage: #{$0} PROJECT" if ! path
  
  Bgo::Git::Project.open(path) do |proj|
    print_project(proj)
  end

end
