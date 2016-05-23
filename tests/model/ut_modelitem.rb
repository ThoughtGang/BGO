#!/usr/bin/env ruby
# Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
# Unit test for BGO ModelItem class

require 'bgo/model_item'

require 'test/unit'

# ----------------------------------------------------------------------
# Test classes
class LeafItem
  extend Bgo::ModelItemClass
  include Bgo::ModelItemObject
  def self.path_elem; 'leaf'; end
  attr_reader :ident
  def initialize(id); @ident = id; @inners = []; end
end

class InnerChildItem
  extend Bgo::ModelItemClass
  include Bgo::ModelItemObject
  def self.child_iterators; [:inners, :leaves]; end
  def self.path_elem; 'inner'; end
  attr_reader :ident
  def initialize(id); @ident = id; @inners = []; @leaves = []; end
  def inners(&block); @inners.each(&block); end
  def inner(id); @inners.select { |x| x.ident == id }.first; end
  def add_inner(id); obj = InnerChildItem.new(id); obj.modelitem_init_parent(self); @inners << obj; obj; end
  def leaves(&block); @leaves.each(&block); end
  def leaf(id); @leaves.select { |x| x.ident == id }.first; end
  def add_leaf(id); obj = LeafItem.new(id); obj.modelitem_init_parent(self); @leaves << obj; obj; end
  def instantiate_child(objpath, recurse_parent=true, recurse_child=false)
      super objpath, recurse_parent, false
  end
end

class OuterChildItem
  extend Bgo::ModelItemClass
  include Bgo::ModelItemObject
  def self.child_iterators; [:inners]; end
  def self.path_elem; 'outer'; end
  attr_reader :ident
  def initialize(id); @ident = id; @inners = []; end
  def inners(&block); @inners.each(&block); end
  def inner(id); @inners.select { |x| x.ident == id }.first; end
  def add_inner(id); obj = InnerChildItem.new(id); obj.modelitem_init_parent(self); @inners << obj; obj; end
end

class RootItem
  extend Bgo::ModelItemClass
  include Bgo::ModelItemObject
  def self.child_iterators; [:outers, :inners]; end
  #def self.path_elem; 'inner'; end
  attr_reader :ident
  def initialize(id); @ident = id; @outers = []; @inners = []; end
  def obj_path(rel=false, root=false)
    root ? self.class.name.downcase + ':' + ident : ''
  end
  def abs_obj_path(objpath); File.join(obj_path(false, true), objpath); end
  def instantiate_child(objpath, recurse_parent=false, recurse_child=true)
      if objpath.start_with? obj_path(false, true)
        objpath = objpath.split(File::SEPARATOR).first
      end
      super objpath, false, recurse_child
  end
  def inners(&block); @inners.each(&block); end
  def inner(id); @inners.select { |x| x.ident == id }.first; end
  def add_inner(id); obj = InnerChildItem.new(id); obj.modelitem_init_parent(self); @inners << obj; obj; end
  def outers(&block); @outers.each(&block); end
  def outer(id); @outers.select { |x| x.ident == id }.first; end
  def add_outer(id); obj = OuterChildItem.new(id); obj.modelitem_init_parent(self); @outers << obj; obj; end
end

# ----------------------------------------------------------------------
class TC_ModelItemTest < Test::Unit::TestCase
  def test_1_hierarchy

    # create root object
    root = RootItem.new('ut-root')
    assert_equal('ut-root', root.ident)
    assert_equal('rootitem:ut-root', root.obj_path(false, true))
    assert_equal('', root.obj_path)
    assert_equal(0, root.descendants.count)

    # add a ton of child objects
    num_outer = 4
    num_outer_inner = 2
    num_outer_inner_inner = 3
    num_outer_inner_inner_leaf = 2
    num_inner = 5
    num_inner_leaf = 7
    num_inner_inner = 1
    num_inner_inner_leaf = 6
    num_outer.times do |i| 
      obj = root.add_outer("#{i}")
      num_outer_inner.times do |j|
        obj2 = obj.add_inner("#{i}.i-#{j}")
        num_outer_inner_inner.times do |k| 
          obj3 = obj2.add_inner("#{i}.i-#{j}.i-#{k}")
          num_outer_inner_inner_leaf.times do |m| 
            obj3.add_leaf("#{i}.i-#{j}.i-#{k}.#{m}")
          end
        end
      end
    end
    count = num_outer + (num_outer * num_outer_inner) +
           (num_outer * num_outer_inner * num_outer_inner_inner) + 
           (num_outer * num_outer_inner * num_outer_inner_inner *
            num_outer_inner_inner_leaf)
    assert_equal(count, root.descendants.count)

    num_inner.times do |i|
      obj = root.add_inner("i-#{i}")
      num_inner_leaf.times do |j|
        obj.add_leaf("i-#{i}.#{j}")
      end
      num_inner_inner.times do |j| 
        obj2 = obj.add_inner("i-#{i}.i-#{j}")
        num_inner_inner_leaf.times do |k|
          obj2.add_leaf("i-#{i}.i-#{j}.#{k}")
        end
      end
    end
    count += num_inner + (num_inner * num_inner_inner) +
            (num_inner * num_inner_leaf) +
            (num_inner * num_inner_inner * num_inner_inner_leaf)
    assert_equal(count, root.descendants.count)

    # To preview paths:
    #root.descendants { |c| puts c.obj_path }

    # iterate with block to limit
   
    # instantiate by path
    # children of root
    path = '/outer/3'
    assert_equal('3', root.instantiate_child(path).ident)
    path = '/outer/3/inner/3.i-1'
    assert_equal('3.i-1', root.instantiate_child(path).ident)
    path = '/outer/3/inner/3.i-1/inner/3.i-1.i-2'
    assert_equal('3.i-1.i-2', root.instantiate_child(path).ident)
    path = '/outer/3/inner/3.i-1/inner/3.i-1.i-2/leaf/3.i-1.i-2.1'
    assert_equal('3.i-1.i-2.1', root.instantiate_child(path).ident)

    out2 = root.instantiate_child('/outer/2')
    # no leading / in path
    assert_equal(out2, out2.instantiate_child('outer/2'))
    # direct-child relative path
    assert_equal('2.i-1', out2.instantiate_child('inner/2.i-1').ident)

    # absolute path
    assert_equal('2.i-1', out2.instantiate_child('/outer/2/inner/2.i-1').ident)
    assert_equal('2.i-1.i-2.1',
                 out2.instantiate_child(
                 '/outer/2/inner/2.i-1/inner/2.i-1.i-2/leaf/2.i-1.i-2.1').ident)

    # inferred child
    assert_equal('2.i-1', root.instantiate_child('inner/2.i-1').ident)
    # should pass: second inner is direct child of first inner
    assert_equal('2.i-1.i-2', out2.instantiate_child('inner/2.i-1.i-2').ident)
    # should pass: second inner is direct child of first inner
    assert_equal('2.i-1.i-2', root.instantiate_child('inner/2.i-1.i-2').ident)
    # should pass: leaf is direct child of first inner
    assert_equal('i-1.2', root.instantiate_child('leaf/i-1.2').ident)
    # should fail : inner does not recurse to second inner
    assert_equal(nil,root.instantiate_child('leaf/2.i-1.i-2.1'))

    # check paths
  end

  def test_2_object_path
    # TODO: test object naming for cleaning bad chars
    # abs path
    # uuid
  end

  def test_3_comments
  end

  def test_4_tags
  end

  def test_5_properties
  end

  def test_6_serialization
  end

  def test_7_current_author
  end
end

