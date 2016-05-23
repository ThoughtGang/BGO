#!/usr/bin/env ruby
# :title: Bgo::Target
=begin rdoc
BGO Target module.
Copyright 2013 Thoughtgang <http://www.thoughtgang.org>

Methods common to Target objects such as File or Process.
=end

require 'bgo' # auto-load BGO datamodel classes as-needed 

require 'bgo/scope'
require 'bgo/reference'

# TODO:  scope mgt (delegate to block scope?)
#        reference mgt
#        support nested targets (e.g. child files)

module Bgo

# =============================================================================
=begin rdoc
A Target is a ModelItem contained in a Project and which wraps the bytes
(Image) to be analyzed. Note that a Target does not store Address objects
directly, but contains one or more AddressContainer objects.

Examples of Target objects include TargetFile and Process objects.
Additional Target types such as NetworkPacket or DataFile may be supported
in the future.
=end
  module TargetObject

=begin rdoc
Global scope for Target. All scopes are children of this Scope.
=end
    attr_reader :scope
=begin rdoc
References (and cross-references) defined within Target.
=end
    attr_reader :references

=begin rdoc
Initialize Target instance.
This must be called in the initialize() method of Target classes.
=end
    def target_init
      @scope = Scope.new('GLOBAL')
      @references = References.new
    end

=begin rdoc
Initialize AddressContainer as a child of this Target.
=end
    def target_init_ac(ac)
      # Set parent scope of AddressContainer outer Block to GLOBAL scope
      ac.block.scope.parent = scope
    end

=begin rdoc
Iterate over AddressContainers object in Target.
Note that this is an abstract method: derived classes should alias this
method name to their local AddressContainer iteration method (i.e. :maps for 
Process, :sections for File).
=end
    def address_containers(ident_only=false, &block)
      []
    end

=begin rdoc
Return AddressContainer object for 'ident'.
Note that this is an abstract method: derived classes should alias this
method name to their local AddressContainer instantiation method (i.e.
:map for Process, :section for File).
=end
    def address_container(ident)
      nil
    end

=begin rdoc
Return AddressContainer that contains offset in the specified Image.
=end
    def address_container_for_image_offset(img, offset)
      address_containers.select { |ac| 
        (ac.image.base_image == img.base_image) && 
        (ac.contains_image_offset? offset)
      }.first
    end

=begin rdoc
Add a revision to every AddressContainer child of the Target.
=end
    def add_revision
      address_containers.each { |ac| ac.add_revision }
      nil
    end

    # TODO: symbols(rev) : return list of all symbol objects or ident + name
    #                      recursing children of scope

    def to_target_hash
      {
        :scope => @scope.to_hash,
        :references => @references.to_hash
      }
    end

=begin rdoc
Fill Target object from Hash.
This replaces scope and references.
=end
    def fill_from_target_hash(h)
      @scope = Scope.from_hash h[:scope]
      @references = References.from_hash h[:references]
    end

    # ----------------------------------------------------------------------
=begin
Analyze TargetObject using a Plugin supporting the :analysis interface. The 
'plugin' argument is the Plugin name, or nil to use the highest-rated Plugin. 
This returns an AnalysisResults object (the output of the :analysis interface),
or false if no suitable plugin could be found. 
Note: This will raise a NameError if PluginManager has not been started.
=end
    def analyze(plugin=nil, opts={})
      begin
        args = [self, opts]
        PluginManager.invoke_spec( :analysis, plugin, *args )
      rescue PluginManager::NoSuitablePluginError
        false
      end
    end

=begin rdoc
Invoke TargetObject#analyze and store the results in the TargetObject#analysis 
Hash.
=end
    def analyze!(plugin=nil, opts={})
      results = analyze(plugin, opts)
      @analysis ||= {}
      @analysis[results.ident] = results
    end

=begin rdoc
Return the analysis results Hash for this TargetObject.
=end
    def analysis
      @analysis || {}
    end

  end

end
