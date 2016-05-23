#!/usr/bin/env ruby
# :title: Bgo::ModelItem
=begin rdoc
BGO Data Model Item module.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/util/json'
require 'bgo/comment'
require 'bgo/tag'

require 'bgo' # auto-load BGO datamodel classes as-needed 

$DEBUG_OBJPATH ||= false
# Enable this when debugging object-path instantiation issues.
# $DEBUG_OBJPATH = true

module Bgo

# =============================================================================
=begin rdoc
A ModelItem class. 
BGO Data Model items must extend this module.
=end
  module ModelItemClass

    include JsonClass

    # registry of all ModelItem classes
    @modelitem_classes = []
    def self.extended(cls)
      if ! (@modelitem_classes.include? cls)
          @modelitem_classes << cls
      end
    end

=begin rdoc
Returns Enumerator over all ModelItem derived classes
=end
    def self.classes
      @modelitem_classes.each
    end

=begin rdoc
Parse JSON data with error handling.

Note: this is just generic JSON parsing code. The classes encoded in the JSON
data must have a json_create method instantiated for it to work.
=end
    # FIXME: remove self? This shouldn't be a module class member
    def self.from_json(str)
      JsonClass.from_json(str, true)
    end

=begin rdoc
JSON callback for instantiating object. This uses the class's from_hash method.
=end
    def json_create(o)
      # TODO: handle Properties Hash and AuthoredComments
      from_hash(o['data'].inject({}) { |h,(k,v)| h[k.to_sym] = v; h })
    end

=begin rdoc
List of ModelItem classes on which this class depends for instantiation.
Used during de-serialization.
=end
    def dependencies
      []
    end

=begin rdoc
A list of symbols used to iterate over children. Each of these symbols will
be used as an argument to self.send, and passed a block.
Derived classes should override this method if they intend their children
to be reached via top-level searches (e.g. for Comments or Properties).
See #descendants.
=end
    def child_iterators
      []
    end

=begin rdoc
The default child to use during instantiation by object path, if the child 
modelitem type is not specified.

This returns a Symbol. The default implementation always returns :invalid.

Derived classes should support this if they want the modelitem type for a child
to be optional in an object path. This is likely only going to be the case for
Map and Section objects, whose default child will be :address.
=end
    def default_child
      :invalid_object_ident
    end

=begin rdoc
Name of ModelItem class in Path.
=end
    def path_elem
      name.split(':').last.downcase     # the split() removes the Bgo:: prefix
    end

=begin rdoc
Convenience routine to instantiate an Image object from a Hash.
The hash can contain any (or none) of the following keys:
  :image : the ident or object path of the Image
  :image_obj : the (de-serialized_ Image object
If proj is supplied, it will be used to instantiate the Image based on the
contents of the :image key.

Note: this raises a ModelItem::InvalidChildError if the Image was not found.
=end
    def image_from_hash!(h, proj=nil)
      img_ident = h[:image].to_s
      img = h[:image_obj]
      if proj && img_ident
        img ||= proj.image(img_ident)
        img ||= proj.item_at_obj_path img_ident
      end

      raise ModelItemObject::InvalidChildError.new(Bgo::Image.name, img_ident
                                               ) if (! img.kind_of? Bgo::Image)
      img
    end

  end

# =============================================================================
=begin rdoc
A ModelItem class instance.
All BGO Data Model items must include this module.
=end
  module ModelItemObject

    include JsonObject

    class InvalidChildError < ArgumentError
      def initialize(cls_name, objpath)
        super "No child found for '#{objpath}' [#{cls_name}]"
      end
    end

=begin rdoc
ModelItem that owns or contains this object, or nil. This is primarily used
only to generate the ObjectPath for a ModelItem object.
Note: This should only be nil for top-level objects, e.g. Project.
=end
    attr_reader :parent_obj
=begin rdoc
AuthoredComments collection containing the comments associated with ModelItem.
This acts as a Hash [ Symbol -> Hash[String -> String] ] of Context Symbol to a 
Hash of Author String to Comment String.
Note: It is recommended that comments be managed through the ModelItem methods
when possible, in order to make current_author default to something sensible.
=end
    attr_reader :comments
=begin rdoc
TagList collection associated with ModelItem. This acts as an Array of Symbols.
=end
    attr_reader :tags

=begin rdoc
Return ident for Modelitem.
All derived classes must re-implement this method.
=end
    def ident
      "ERROR: IDENT MISSING FROM MODELITEM"
    end

=begin rdoc
Represent ident as a string for use in object path.
This defaults to self.ident.to_s.
=end
    def ident_str
      ident.to_s
    end

=begin rdoc
Return root of the Modelitem object tree.
This recurses up the object tree to the root.
=end
    def root
      @cached_root ||= (@parent_obj ? @parent_obj.root : self)
    end

=begin rdoc
Initialize ModelItem instance.
This must be called in the initialize() method of ModelItem classes.
=end
    def modelitem_init
      @comments = AuthoredComments.new
      @tags = TagList.new
      # NOTE: @properties is created lazily
      @properties = nil
      @parent_obj = nil
    end

=begin rdoc
Initialize modelitem instance as child of 'obj'.
Thist just sets @parent_obj to obj.
=end
    def modelitem_init_parent(obj)
      @parent_obj = obj
    end

    # ----------------------------------------------------------------------
    # Comment accessors

=begin rdoc
Set comment for ModelItem object. This will default to context 'general'
(CTX_GEN) if context is nil, and to the output of current_author() if author 
is nil.
Generally, this is the desired behavior, so set_comment should be used instead
of modifying the AuthoredComments member (comments) directly.
=end
    def set_comment(text, context=nil, auth=nil)
      @comments.add(text, auth || current_author, context || Comment::CTX_GEN)
    end

=begin rdoc
Return comment for ModelItem.
This is the simplified accessor to AuthoredComments: it returns the comment
for context 'general' (CTX_GEN) created by the current author. 
More detailed access can be obtained by reading the AuthoredComments member
('comments') directly.
=end
    def comment(context=nil, auth=nil)
      (@comments[context || Comment::CTX_GEN] || {})[auth || current_author]
    end

=begin rdoc
Set comment for ModelItem.
This is a simplified accessor to AuthoredComments: it sets the comment for 
context 'general' (CTX_GEN), attributed to the current author. 
More detailed access can be obtained by using set_comment().
=end
    def comment=(text)
      set_comment(text)
    end

=begin rdoc
Set a tag for item.
This adds a Tag to the TagList for the ModelItem. The Tag will be registered 
with the TagRegistry of the ModelRootItem, if it has not already been 
registered.
=end
    def tag(sym)
      register_tag(sym)
      @tags.add(sym)
    end

=begin rdoc
Register a Tag with the TagRegistry of the ModelRootItem. This will recurse up
the object tree until a poarent overrides this method (as ModelRootItem does).
=end
    def register_tag(sym, descr=nil)
      # note: we cannot just invoke root.register_tag -- endless recursion
      @parent_obj.register_tag(sym, descr) if @parent_obj
    end

=begin rdoc
Hash of user-supplied data. This is serialized with the ModelIten object, and
can be used by applications or plugins to store persistent per-object data.
=end
    def properties
      # Note: this is created lazily as most objects won't have properties
      @properties ||= {}
    end

=begin rdoc
Convenience method for accessing a Property value.
Note: it is recommended to use this instead of ModelItem@properties[name], as 
ModelItem#properties will create an (empty) properties Hash if none exists.
=end
    def property(name)
      (@properties || {})[name]
    end

=begin rdoc
Copy modelitem data (comments, tags, properties) from 'obj' into current
Modelitem. This will not clear existing data, but will overwrite conflicting
data items.
=end
    def dup_modelitem(obj)
      obj.tags.each { |t| @tags.add t }
      obj.comments.values.each { |h| h.values.each { |cmt| @comments << cmt } }
      obj.properties.each { |k, v| properties[k] = v }
    end

=begin rdoc
Return Author String set by application.
This walks up the object tree until author is defined (by re-implementing this 
method).
Note that the root of the object tree (e.g. Project) must provide a means for
the application to set current_author, or current_author will always be
UNKNOWN.
=end
    def current_author
      @parent_obj ? @parent_obj.current_author : Comment::AUTH_UNK
    end

    # ----------------------------------------------------------------------
    # OBJECT PATH

=begin rdoc
Instantiate a child object based on its path.

The object path should have the form
  path_elem/ident[/...]
where path_elem is the output of child.class.path_elem, and ident is the
output of child.ident. If recurse_parent is set, the object path can be an
absolute (from the root of the object tree) path. If recurse_child is set,
the object path can be a partial (i.e. relative to a child of this object) path.
  
This is the default implementation. It assumes that the path_elem of the child
class is a method supported by this ModelItem object for instantiating that 
child type.

NOTE: This method can recurse back through parent objects in order to 
instantiate an absolute object path, or recurse forward through child objects
in order to instantiate an object path where a component is inferred (e.g.
a Map component may be left out of an Address path passed to a Process object
for instantiation). ModelItems which have a large number of children (i.e.
Section or Map) should override this method so that recurse_child is always
false. This will prevent the method from calling Address#instantiate_child on
every Address object stored in the Section or Map.
=end
    def instantiate_child(objpath, recurse_parent=true, recurse_child=true)
      $stderr.puts "#{self.class.name} PARSE #{objpath}" if $DEBUG_OBJPATH
      return nil if (! objpath) or (objpath.empty?)

      c_type, c_ident, rest = pop_object_path_component objpath

      child = nil
      begin
        $stderr.puts "TYPE #{c_type} IDENT #{c_ident}" if $DEBUG_OBJPATH
        child = instantiate_child_from_ident(c_type, c_ident) if \
                c_type && c_ident
        if child
          $stderr.puts "CHILD: #{child.class.name}" if $DEBUG_OBJPATH
          # use child to instantiate rest of path components
          return (rest.empty?) ? child : \
                                 child.instantiate_child(File.join(rest))
        end
      rescue NoMethodError, ArgumentError
        nil
      end

      instantiate_child_recurse(objpath, recurse_parent, recurse_child)
    end

=begin rdoc
Wrapper for ModelItem#instantiate_child which raises an InvalidChildError if
item cannot be found.
=end
    def instantiate_child!(objpath, recurse_parent=true, recurse_child=true)
      child = instantiate_child(objpath, recurse_parent, recurse_child)
      raise InvalidChildError.new(self.class.name, objpath) if ! child
    end

=begin rdoc
Instantiate a ModelItem from its object path. This is just a wrapper for
root.instantiate_child.
=end
    def item_at_obj_path(objpath)
      root.instantiate_child(objpath, false, true)
    end

=begin rdoc
Iterate over all descendants, recursively. Every child ModelItem is passed to
the block. The return value of the block is ignored.
This is primarily intended for examining components common to all ModelItems,
e.g. Comments or Tags.
Note that this relies on the class method child_iterators() to determine
which iterators to invoke. If an iterator is not included in the Array returned
by this method, it will not be invoked.
=end
    def descendants(&block)
      return to_enum(:descendants) unless block_given?
      self.class.child_iterators.each do |it| 
        self.send(it) { |c| yield c; c.descendants(&block) }
      end
    end

=begin rdoc
Return the ObjectPath for this ModelItem object. This returns a string of the
form:
  parent_obj.obj_path/class.path_elem/ident
  class.path_elem/ident
...depending on whether or not parent_obj is defined. This means that 
ObjectPaths are generated recursively by referencing the parent ModelItem 
object.

Note that a relative path can be forced by setting 'rel' to true. Similarly,
a project-independent path can be generated by setting 'rel' to false and
'root' to true.
=end
    def obj_path(rel=false, root=false)
      elem = []
      elem << parent_obj.obj_path(rel, root) if (parent_obj && ! rel)
      elem << self.class.path_elem
      elem << self.ident.to_s
      File.join(*elem)
    end

=begin rdoc
Wrapper for obj_path that forces generation of a project-independent ObjPath.
=end
    def uuid; obj_path(false, true); end

    # ----------------------------------------------------------------------
    # SERIALIZATION
=begin rdoc
Convert ModelItem to Hash.
This returns a Hash with the :properties, :comments, and :tags keys.
=end
    def to_modelitem_hash
      { 
        :properties => @properties,
        :comments => @comments.to_hash,
        :tags => @tags
      }
    end

=begin rdoc
Fill ModelItem object from Hash.
This replaces properties, tags, and comments with those in the Hash.
=end
    def fill_from_modelitem_hash(h)
      @properties = h[:properties] if h[:properties]
      @tags = TagList.new( (h[:tags] || []).map { |t| t.to_sym } )
      @comments = AuthoredComments.from_hash(h[:comments]) if h[:comments]
    end

=begin rdoc
Generate a ModelItemFactory from JSON representation.
=end
    def to_json(*arr)
      self.to_hash.to_json(*arr)
    end

=begin rdoc
Save changes made to a ModeItem.
This is used to force a commit in an on-disk project. It has no effect on
in-memory model items.
=end
    # TODO: Make this a method only for Project?
    def save(msg='No details', author='Anonymous'); end # nothing to do

=begin rdoc
Write changes made to a ModeItem.
This is used to force a write in an on-disk project. It has no effect on
in-memory model items.
=end
    # TODO: Make this a method only for Project?
    def update(&block); end # nothing to do

=begin rdoc
Human-readable 'inspect' method.
This is generally used by command line tools to display ModelItem contents.
The default implementation returns an Array of strings that contain basic
ModelItem info such as the ident, class, object path, properties, tags, and
comments.
NOTE: This returns an Array of strings, not a String, in order to facilitate
indenting and ordering by the caller.
=end
    def details
      details_id + details_tags + details_properties + details_comments
    end

=begin rdoc
Human readable description of the ModelItem object identifying info.
=end
    def details_id
      [ "ident: #{ident_str}",
        "class: #{self.class.name}",
        "object-path: #{obj_path}" ]
    end

=begin rdoc
Human readable description of the ModelItem object tags.
=end
    def details_tags
        ['tags:'].concat @tags.map { |t| "\t'#{t.to_s}'" }
    end

=begin rdoc
Human readable description of the ModelItem object properties
=end
    def details_properties
      props = @properties || {}
      ['properties:'].concat props.map { |k,v| "\t#{k} = #{v.inspect}" }
    end

=begin rdoc
Human readable description of the ModelItem object comments. 
=end
    def details_comments
      arr = ['comments:']
      @comments.each do |ctx, h|
        arr << "\tcontext: #{ctx.to_s}"
        h.each { |auth, cmt| arr << "\t\t#{cmt.to_s}" }
      end
      arr
    end

=begin rdoc
Convenience function to remove the first line (usually a header) and the 
first character of each line (usually a TAB) from the output of a details_*
method.
=end
    def details_clean(arr)
      arr[1..-1].map { |line| line[1..-1] }
    end

    protected

=begin rdoc
Perform object path lookup on children or parent, as appropriate. This is
invoked when the current object cannot resolve the object path.
=end
    def instantiate_child_recurse(objpath, recurse_parent, recurse_child)
      child = nil
      # path may have been absolute: try instantiating through parent
      if recurse_parent && @parent_obj
          child = @parent_obj.instantiate_child(objpath, true, false)
      end
      # path may have an implicit child: try instantiating through children 
      if ! child && recurse_child
        self.class.child_iterators.each do |it| 
          self.send(it) { |c| 
            child = c.instantiate_child(objpath, false, true)
            break if child
          }
          break if child
        end
      end

      child
    end

=begin rdoc
Extract modelitem type and ident from the first two elements of objpath.
If only one path item is present, it will be used for ident, and
modelitem type will be set to the default child.

This returns an Array [String, String, Array] containing the modelitem type,
the ident, and the rest of the path components.
=end
    def pop_object_path_component(objpath)
      sep = File::SEPARATOR
      c_type, c_ident, *rest = objpath.sub(/#{sep}*/, '').split(sep)

      # attempt 
      if c_type && ! c_ident
        c_ident = c_type
        c_type = self.class.default_child.to_s
      end

      c_type &&= c_type.to_sym
      [c_type, c_ident, rest]
    end

=begin rdoc
Default implementation of instantiate_child_from_ident. This just invokes
the method with the same name as 'sym', with 'child_ident' as the argument.

Derived classes should override this method if any children need to convert
ident from a String (e.g. to a Fixnum) before being instantiated.
=end
    def instantiate_child_from_ident(sym, child_ident)
      (self.respond_to? sym) ? self.send(sym, child_ident) : nil
    end

  end

# =============================================================================
=begin rdoc
The Root item of a BGO ModelItem tree.
This generally has only one derived class: Project.
=end
  class ModelRootItem
    extend Bgo::ModelItemClass
    include Bgo::ModelItemObject

=begin rdoc
TagRegistry for this containing all Tags definedin the Model.
Note that is only a Hash of Tag symbols to Tag descriptions. To find all
instances of a Tag, the descendants() method must be used:
  descendants { |child| child.tags.include? sym }
=end
    attr_accessor :tag_registry

=begin rdoc
Current author (user of application) for comments and such.
=end
    attr_accessor :current_author

    # TODO: serialization (read, write tag registry and author)

    def initialize
      modelitem_init
      @tag_registry = TagRegistry.new
    end

    def root
      self
    end

    def instantiate_child(objpath, recurse_parent=false, recurse_child=true)
      objpath = objpath.sub(/#{File::SEPARATOR}*/, '')
      # strip project path from objpath
      if objpath.start_with? obj_path(false, true)
        objpath = File.join(obj_path.split(File::SEPARATOR)[1..-1])
      end
      super objpath, false, recurse_child
    end

=begin rdoc
Generate an absolute (preject-independent) ObjectPath for a project-specific
ObjectPath. This just prepends self.object_path to objpath.
=end
    def abs_obj_path(objpath)
      File.join(obj_path(false, true), objpath)
    end

=begin rdoc
Register a tag for this project
=end
    def register_tag(sym, descr=nil)
      @tag_registry.register(sym, descr)
    end

  end

end
