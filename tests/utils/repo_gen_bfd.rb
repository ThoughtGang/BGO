#!/usr/bin/env ruby
# Copyright 2011 Thoughtgang <http://www.thoughtgang.org>
# Generate BGO::Git repository based on BFD Plugin

require 'test/unit'
require 'bgo/plugin'

require 'bgo/git/project'
require 'bgo/git/process'
require 'bgo/git/file'

class TC_BfdRepoGen < Test::Unit::TestCase
  DIR = File.dirname(__FILE__) + File::SEPARATOR + 'repos'
  TGT_DIR = File.dirname(__FILE__) + File::SEPARATOR + 'targets'

  DEBUG=false
  #DEBUG=true

  def setup
    Dir.mkdir(DIR) if not File.exist?(DIR)

    path = DIR + File::SEPARATOR + 'bfd.bgo'
    FileUtils.remove_dir(path) if File.exist?(path)

    @proj = Bgo::Git::Project.new(path, 'BFD Example', 'Targets loaded via BFD')
    Bgo::PluginManager.load_all if Bgo::PluginManager.count < 1
  end

  def test_create_bfd_repo
#    require 'profile'
    
    # create a TargetFile object
    fname = TGT_DIR + File::SEPARATOR + 'linux-2.6.x-64.bin'
    buf = nil
    File.open(fname, 'rb') { |f| buf = f.read }
    ident = Bgo::Git::TargetFile.create(@proj.root, fname)
    f = Bgo::Git::TargetFile.factory(@proj.root, ident)
    assert_not_nil(f)

    # create a Process object for TargetFile
    args = { :filename => fname, :command => fname }
    ident = Bgo::Git::Process.create(@proj, args)
    p = Bgo::Git::Process.factory(@proj, ident)
    assert_not_nil(p)

    plugin = Bgo::PluginManager::find('File').first
    assert_not_nil(plugin)

    # Identify TargetFile
    fh = File.open(fname, 'rb')
    id = plugin.invoke_interface(Bgo::Plugin::IFACE_IDENT_FILE, fh)
    assert_equal(Bgo::Ident, id.class)
    assert(id.recognized?)

    plugin = Bgo::PluginManager::find('Objdump').first
    assert_not_nil(plugin)

    # Parse TargetFile contents
    plugin.invoke_interface( Bgo::Plugin::IFACE_PARSE_FILE, f )

    # Load TargetFile into Process
    plugin.invoke_interface( Bgo::Plugin::IFACE_LOAD_FILE, p, f )

    # objdump-based disassembly
    plugin = Bgo::PluginManager::find('Objdump').first
    assert_not_nil(plugin)

    puts "\nGenerating disassembly. This will take awhile..."
    @proj.transaction do
      propagate

      p.maps.each do |m|
        next if not m.executable?
        puts "Map #{m.ident} (#{m.size} bytes)"

        addrs = {}
        task = Bgo::LinearDisasmTask.new(m.start_addr, nil, addrs)
        plugin.invoke_interface( Bgo::Plugin::IFACE_DISASSEMBLE, task, m )

        count = 0 if DEBUG
        addrs.keys.sort.each do |vma|
            puts "Adding address for VMA %X" % vma if DEBUG
            a = addrs[vma]
            begin
              addr = m.add_address(a.vma, a.size, a.comment)
              addr.contents = a.contents

              if DEBUG
                puts addr.inspect
                count += 1
                break if count > 100
              end
            rescue Exception => e
              puts "ERROR ADDR #{vma}:\n#{e.message}\n#{e.backtrace.join("\n")}"
              raise
            end
        end # each addr

      end   # each map

    end     # transaction

  end

end
