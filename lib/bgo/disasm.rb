#!/usr/bin/env ruby                                                             
# :title: Bgo::Disasm
=begin rdoc
BGO Disassembler support

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

module Bgo

=begin rdoc
Generic disassembly task.

A DisasmTask is passed to the :disassemble interface of a plugin, along
with the disassembly target (a Section, Map, or Buffer). The DisasmTask 
object contains all of the additional information needed by the disassembler to 
perform the requested disassembly (e.g. starting address, Hash of visited
addresses, etc).

Note that the DisasmTask provides for two forms of output: an object that
responds to the Hash assignment function []= (where the key is VMA and the
value is an Address object), and/or a Proc object that will be passed the
Address object for each instruction as it is disassembled. The specifics
of how these outputs will be used (in terms of ordering and repetition) is
determined by each strategy.

It is recommended that the Disassemble class be used to wrap DisasmTasks, as
the API is much more user-friendly. DisasmTasks are mostly useful for 
fine-grained control of a disassembler plugin, or for queueing disassembly
tasks (e.g. in a command pipeline).
=end
  class DisasmTask

=begin rdoc
Address to start disassembly at. This will default to offset 0 in the
target.
=end
    attr_accessor :start_addr
=begin rdoc
Object supporting []= that receives a VMA:Instruction key:value pair to store.
Can be nil.
=end
    attr_accessor :output
=begin rdoc
A callback for each instruction.
Can be nil.
The callback takes a single Address object.
=end
    attr_accessor :handler
=begin rdoc
Hash of plugin-specific options.
These options are passed straight through to the disassembly interface of the
plugin.
=end
    attr_reader :options

=begin rdoc
List of all recognized DisasmTask classes.
=end
    @tasks = []
    def self.inherited(cls)
      @tasks << cls
    end

=begin rdoc
Return canonical name String identifying DisasmTask class.
=end
    def self.canon_name
      instance_variable_get('@canon_name') || self.name
    end

=begin rdoc
Return symbol identifying DisasmTask class.
=end
    def self.sym
      instance_variable_get('@sym') || self.canon_name.to_sym
    end

=begin rdoc
Return Array of supported DisasmTask classes.
=end
    def self.supported
      @tasks.dup
    end

    def initialize(start_addr=nil, output=nil, handler=nil, opts={})
      @start_addr = start_addr
      @output = output
      @handler = handler
      @options = opts
    end

    def linear?; false; end

    def cflow?; false; end

    def emu?; false; end

=begin rdoc
Invoke block to disassemble an address in the target. Returns Address object 
created by block. This method is invoked by subclasses to disassemble a single 
instruction.

A 'target' is a BGO ByteContainer, such as a Map, Section, or Buffer object.

The 'vma' is the load address to disassemble. If 'vma' is nil, start_addr will
be used. This allows subclasses to iterate over multiple addresses, invoking
this method to disassemble each address.

Disassembler plugins call the perform method of the DisasmTask if they 
do not want to re-implement the core algorithm themselves.

The block is invoked with the following arguments:
  image : An Image object containing the bytes of the target
  offset : The Offset into the Image at which to disassemble
  vma : The VMA of the offset (for creation of the Address object)
The block must return an Address object, or nil.

Notes:
  * handler is invoked
  * instruction is added to output
=end
    def perform(target, vma=nil, &block)
      vma ||= start_addr
      offset = target.vma_offset(vma)
      return nil if not offset

      addr = block.call(target.image, offset, vma)     
      if addr
        # invoke callback
        handler.call(addr) if @handler
        # add to output
        output[vma] = addr if @output
      end

      addr
    end
  end

# ----------------------------------------------------------------------
=begin rdoc
Linear Disassembly task.

This task should provide a start address (defaulting to the first address in
the target) and a range (defaulting to the entire target).
=end
  class LinearDisasmTask < DisasmTask

=begin rdoc
Range object which limits the addresses to disassemble. Default is all of 
target.
=end
    attr_reader :range

    @canon_name = 'Linear'
    @sym = :linear

    def initialize(start_addr=0, range=nil, output=nil, handler=nil, opts={})
      @range = range
      super start_addr, output, handler, opts
    end

    def linear?; true; end

=begin rdoc
Disassembles from start_addr to end of range. Invokes DisasmTask#perform to 
generate and store/handle each Address.
=end
    def perform(target, &block)
      return if not target.vma_offset(start_addr)

      vma = start_addr
      max = (range ? range.last : vma + target.size - 1)
      while vma <= max
        addr = super(target, vma, &block)
        vma += addr ? addr.size : 1
      end

    end
  end

# ----------------------------------------------------------------------
=begin rdoc

Addresses are added to 
If visited_addr contains VMA, disassembly for that branch will end.
=end
  class CflowDisasmTask < DisasmTask
=begin rdoc
Hash of visited addresses: the key is the Address VMA, the value is the Address
size. 

By default an internal Hash is used, so that visited addresses are discarded
when disassembly is completed.
=end
    attr_reader :visited
=begin rdoc
Array of branch targets that lie inside of existing instructions. By default,
these are discarded.
=end
    attr_reader :insiders

    @canon_name = 'Control Flow'
    @sym = :cflow
    def initialize(start_addr=nil, visited_addr={}, insiders=nil, output=nil, 
                   handler=nil, opts={})
      @visited = visited_addr
      @insiders = insiders
      super start_addr, output, handler, opts
    end

    def cflow?; true; end

=begin rdoc
Returns true if vma is inside an existing address.
=end
    def vma_inside_addr?(vma, addrs)
      prev_vma = nil
      prev_size = 0

      # Find preceding Address in address list, with a max distance of 32 bytes.
      vma.downto(vma-32) do |addr|
        if addrs.include? addr
          prev_vma = addr
          prev_size = addrs[addr]
          break
        end
      end

      # Does previous Address object contains VMA?
      (prev_vma && (prev_vma + prev_size >= vma))
    end

=begin rdoc
Disassembles, following flow of control, from start_addr to end of target. 
Invokes DisasmTask#perform to generate and store/handle each Address.

Notes:
  * requires that insn.branch? and insn.fallthrough? be accurate
  * branches are followed after linear disassembly completes.
  * duplicate addresses are ignored.
=end
    def perform(target, &block)
      target_vmas = [ start_addr ]
      while (target_vmas.count > 0)
        vma = target_vmas.shift

        # Check if this entry point is inside another address
        if vma_inside_addr?(vma, visited)
          insiders << vma if insiders
          next
        end

        cont = true
        while (cont && target.vma_offset(vma))
          break if visited.include? vma

          addr = super target, vma, &block
          # TODO: raise exception?
          break if not addr

          # add to visited_addresses
          visited[vma] = addr.size

          # handle possible banches
          if addr.code?
            insn = addr.contents

            if insn.branch? 
              tgt_vma = nil
              if insn.target.memory? and insn.target.value.fixed?
                tgt_vma = insn.target.value.displacement
              elsif insn.immediate?
                tgt_vma = vma + insn.target.value
              end

              # Add to list of VMAs to disassemble
              target_vmas << tgt_vma if tgt_vma
            end
          end

          # disassemble next address
          cont = insn.fallthrough?
          vma += addr.size
        end
      end

    end
  end

# ----------------------------------------------------------------------
=begin rdoc
Class of convenience functions to generate disasm_requests
=end
  class Disassemble

=begin rdoc
Fetch the most suitable (highest-ranking) plugin for performing the
disassembly task.
=end
    def self.fetch_plugin(task, target)
      args = [task, target]
      Bgo::Application::PluginManager.fittest_providing(:disassemble, *args)
    end

=begin rdoc
Invoke the Disassemble interface in the plugin.
Note: This will raise a NameError if the PluginManager service is not started.
=end
    def self.invoke_plugin(plugin, task, target)
      raise "No disasm plugin available for task" if not plugin
      plugin.invoke_spec( :disassemble, task, target )
    end

=begin rdoc
Extract the standard disassembly arguments from args Hash.
=end
    def self.std_args(args={}, &block)
      output = (args[:output] ? args[:output] : {})
      handler = ((block_given?) ? Proc.new(&block) : nil)
      opts = (args[:opts] ? args[:opts] : nil)
      [output, handler, opts]
    end

=begin rdoc
Disassemble a single address at VMA in target.

Arguments:
  :output:
  :plugin:
  :opts:

block (addr)
=end
    def self.address(target, vma, args={}, &block)
      output, handler, opts = std_args(args={}, &block)

      task = DisasmTask.new(vma, addr_list, handler, opts)

      plugin = args[:plugin] ? args[:plugin] : self.fetch_plugin( task, target )
      invoke_plugin( plugin, task, target )

      addr_list[addr_list.keys.first]
    end

=begin rdoc
Perform Linear disassembly on target starting at VMA.

Arguments:
  :end_vma:
  :output:
  :plugin:
  :opts:

block (addr)
=end
    def self.linear(target, vma=nil, args={}, &block) 
      vma = target.start_addr if not vma
      end_vma = (args[:end_vma] ? 
                 args[:end_vma] : target.offset_vma(target.size-1))
      output, handler, opts = std_args(args, &block)

      task = LinearDisasmTask.new(vma, Range.new(vma, end_vma), output, 
                                  handler, opts)

      plugin = args[:plugin] ? args[:plugin] : self.fetch_plugin( task, target )
      invoke_plugin( plugin, task, target )

      output
    end

=begin rdoc
Perform Control-flow disassembly on target starting at VMA.

Arguments:
  :visited:
  :output:
  :insiders: List to be populated with branch targets that lie inside 
existing instructions
  :plugin:
  :opts:

block (addr)
=end
    def self.cflow(target, vma, args={}, &block) 
      # A visited_addresses Hash is required
      visited = args[:visited] ? args[:visited] : {}
      # Keeping track of 'in-betweener' addresses is not
      insiders = args[:insiders] ? args[:insiders] : nil
      output, handler, opts = std_args(args={}, &block)

      task = CflowDisasmTask.new(vma, visited, insiders, output, handler, opts)

      plugin = args[:plugin] ? args[:plugin] : self.fetch_plugin( task, target )
      invoke_plugin( plugin, task, target )

      output
    end

=begin rdoc
NOT IMPLEMENTED
=end
    def self.emu(target, vma, plugin=nil, options={}) 
      raise NotImplementedError
    end

  end

end
