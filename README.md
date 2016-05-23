# BGO
Binary Generic Objects: a framework for binary analysis

See README.STATUS for current status of the project.


# Purpose

There are many open-source tools available for binary analysis: binutils, 
capstone, elfsh, llvm, metasm, radare, volatility... the list keeps growing.

The BGO project aims to provide a platform for integrating these targeted
tool into a more general-purpose analysis suite. The BGO framework provides
no native loaders, disassemblers, debggers, or tracers; instead, it uses
plugins to invoke external tools and convert their output into BGO's
data model. This allows unrelated analysis tools to be chained together, and
additional plugins can be developed to operate entirely on the BGO 
representation.

Applications such as user interfaces or server-side processes can be built on
top of the BGO framework in order to provide a standard interface to the user
of these external anaysis tools.


# Features

* scriptable in Ruby
* extensible, plugin-base architecture
* Git-backed projects for version control and distributed collaboration
* JSON serialization
* access to Java classes (and JARs) via jruby 
* "layer"-based representation of memory addresses to accomodate different interpretations of code and data, or changes to code and data over time


# Examples

See README.STATUS and README.COMMAND for examples of using the framework and
the CLI.


# Applications

The BGO framework includes the bgo command line utility, which provides a 
toolchain for binary analysis.

Ream (unreleased) is a Qt4 reverse engineering and refactoring tool built on top
of BGO.

ReWB (unreleased) is a Qt4 UI for BGO.

ReHash (unreleased) is a GitLab-based web application for collaborative
reverse engineering, based on the BGO framework.


# Data Model

ModelItem - A sort of ActiveRecord for BGO data types. ModelItems store
            metadata and track parent/child nodes. Git-backed ModelItems
	    serialize to disk; in-memory ModelItems do not.
  - obj_path : path to object in current project (e.g. /process/1000/map/999)
  - uuid : project-independent obj_path
  - ident : Unique identifier for this object, often used as a key
  - properties : Hash of user-supplied data
  - comments : Hash of Context (Symbol) to a Hash of Author (String) to
               Comment (String). This means each author can have a single
	       context-specific comment per object.
  - tags : Array of Symbols which represent tags for objects


Comment - A comment attached to a ModelItem.
  - author
  - content
  - timestamp
  - text


Project - The basic working environment in BGO. A Project can contain
          multiple related Files, Images, Processes, etc. A Git-backed
	  Project is also a Git repository, meaning that Git can be used to
	  collaborate on a single Project.
  - name
  - description
  - bgo_version
  - created
  - files : Iterator over TargetFile objects
  - packets : Iterator over Packet objects
  - images : Iterator over Image objects
  - processes : Iterator over Process objects
  - comments : All ModelItem comments in Project objects
  - tags : All ModelItem tags in Project objects
  - properties : All ModelItem properties in Project objects
  - symbols : All symbol tables in File and Process objects


TargetFile - Associates an Image object with an on-disk file. A TargetFile
             can contain nested child TargetFile objects, as in an archive.
  - name
  - full_path
  - dir
  - child_files

 
Packet - A contiguous sequence of bytes from an Image which can be divided into
         Section objects, but which cannot be loaded into a Process object. This
	 is used to represent network packet data.


Image - A sequence of bytes. This can be the contents of a file, the contents 
        of a location in memory, or the contents of a patch, and so forth. 
	All binary data is stored in an Image object.
  - ident : the SHA digets of the Image contents
  - contents


RemoteImage - A sequence of bytes whose contents lie outside the Project (and 
              the Project repository). This allows binary images to be stored 
              outside of the Project in order to accomodate concerns about
	      storage space or security.


VirtualImage - An Image that has no on-disk contents, such as a zero-initialized
               area of memory.
  - size
  - fill


PatchedImage - An in-memory representation of an Image whose bytes have been
               modified ("patched").  This associates a base Image object
	       with an ImageChangeset and a Revision number.
  - start_addr
  - changeset
  - revision


ImageChangeset - A sequence of revisions to an Image. Each revision is a 
                 collection of bytes that have changed in the Image, or
                 Address objects that have been defined on the Image.
  - current_revision
  - base_image
  - start_addr


ImageRevision - This contains Address objects and byte patches to the base
                Image object that are defined in this ImageRevision. This is
		managed by ImageChangeset.


ArchInfo - Architecture information for a file or image.
  - arch : CPU architecture
  - mach : CPU model or revision
  - endian


Ident - Identification information for code or data
  - format : file format (e.g. ELF, JPG)
  - summary 
  - full
  - mime
  - contents (:code | :data)


Section - A contiguous sequence of bytes in a TargetFile or Packet. This is
          normally used in object file formats to distiguish between code, 
	  data, and metadata. The Section object contains Address objects,
          such as the results of static disassemby.
  - ident
  - name
  - file_offset
  - size
  - flags : (rwx)
  - addresses


Process - Representation of an OS process, which includes mapping one or more
          Image objects into a virtual memory region.
  - ident : A numeric ID for this process. This corresponds to PID, and is
            arbitrary (but unique within the project) unless the Process object
	    is being created from a tracing utility. The same command line or
	    executable can be used with different idents in order to represent
	    multiple executions of the same program (e.g. a server process)
	    which vary based on runtime input
  - command  : Command line used to launch this process. The same executable
               can be used with multiple commands in order to represent
	       different executions of the same program which vary based on
	       command line arguments
  - filename : Name of the TargetFile object for the main executable of this
               process, if applicable
  - arch_info
  - maps
  - addresses


Map - A mapping of a portion of an Image into a Procss address space.
  - vma
  - size
  - image
  - image_offset
  - arch_info
  - addresses


Address : An address definition. This defines a region of fixed size at a 
specific VMA in a Process, or at an offset into a File.
  - image
  - vma
  - offset
  - size
  - bytes
  - names
  - references
  - content_type (:code | :data | :unknown)
  - contents : An Instruction or data object


Instruction - An assembly language instruction. This associates an Opcode object
             with an OperandList object to represent a disassembled instruction
	     for a specific byte sequence. An Instruction object is considered 
	     to be an instance-of an Opcode object. It consists of an Opcode 
	     object and an OperandList of zero or more Operand objects. Each 
	     Opcode object and each Operand object can be considered a
             Singleton object, and may be stored as such in the backend 
	     database in order to conserve space.
  - arch : CPU Architecture
  - ascii : ASCII (String) representation of the instruction
  - opcode : Opcode object
  - prefixes : Array of instruction prefixes (Strings)
  - side effects : Array of side effects for combination of Opcode + Operands
  - operands : Array of Operand objects
  - comment : Comment for all occurrences of instruction


Opcode - A CPU instruction definition, ignoring operands. Generally, there will
         only be a single instance of each Opcode in memory or in a stored
	 database; all Instruction objects reference the same instruction.
  - mnemonic : ASCII (String) mnemonic of the instruction
  - isa : ISA subset (e.g. General, MMX, SMM, etc) of the instruction
  - category : Descriptive category (e.g. MATH, STACK) of the instruction
  - operations : Array of operations (ADD, SUB, etc) performed by instruction
  - flags_read : Array of flags read by instruction
  - flags_set : Array of flags modified by instruction


OperandList : A subclass of Array for storing an arbitrary number of ordered
              operands
  - dest : Destination operand
  - src : Source operand
  - target : Target of a branch instruction
  - access : Array of access strings (rwx) for each operand


Operand
  - ascii
  - value : a Register, IndirectAddress, or Numeric object


Register : As with Opcode, there will only be a single instance of a Register
           object. This object is shared betweenthe disassembler and the VM.
  - mnemonic : ASCII (String) name of register
  - size : Size of register in bytes
  - type : Type of register, e.g. GEN, FPU, SIMD
  - purpose : Array of strings desribing the general purpose of a register
              (e.g. accumulator, stack pointer, instruction pointer, flags)
  - id : A numeric identifier for the register, unique to each physical
         register (e.g. RAX, EAX, AX, AH, AL have the same id on x86-64)
  - mask : A binary mask of bits that are significant for this register.
          On x86, EAX would be 0xFFFFFFFF, AX would be 0xFFFF, 
	  AH would be 0xFF00, and AL would be 0xFF. Shift is implicit in mask.


IndirectAddress
  - scale
  - index
  - base
  - shift
  - segment


Block - A collection of related instructions. The instructions need not be
        sequential or contiguous. A block is used for descriptive purposes
	and has its own namespace/scope.
  - start_addr
  - size
  - parent
  - scope
  - revision


BasicBlock - A sequence of instructions which has no entry or exit points
             between the start and end instructions.
  - start_addr
  - size
  - parent


Symbol - A mapping from a name to a value.
  - name
  - namespace
  - value

CodeSymbol - an address in a code segment

DataSymbol - an address in a data segment

ConstSymbol - a constant value

HeaderSymbol - a symbol in a file header (metadata) such as a section name


Scope - A collection of Symbols defined in a single scope (usually a Block)
  - children : child (enclosed) Scope objects
  - parent : parent (enclosing) Scope object
  - symbols : Array of Symbol objects defined in this and child scopes


Reference - A reference from one object to another.
  - from : Referrer
  - to : Referent
  - access (rwx)
  - revision : Revision number in changeset

AddRef - Reference to an Address object

FuncRef - Reference to a Function object

FileRef - Reference to a TargetFile object

LibRef - Reference to a Library object

ProcessRef - Reference to a Process object

UriRef - Reference to a URI (String)


DisasmTask - A description of a disassembly task passed to the :disassemble
             method of a Plugin. The Task defines a perform() method which 
	     determines the disassembly algorithm (e.g. linear, control-flow,
	     emulated).
  - start_addr
  - output : Collection of VMA:IAddress key:value pairs
  - handler : optional callback to invoke on each Address object
  - options : a Hash of plugin-specific options

LinearDisasmTask

CflowDisasmTask


# Plugin Architecture

BGO uses the [tg-plugins](https://github.com/ThoughtGang/tg-plugins) module
for its plugin system.

All of the core functionality is implemented in plugins; the framework itself
simply provides project management and a data model.


# License

https://github.com/mkfs/pogo-license

This is the standard BSD 3-clause license with a 4th clause added to prohibit 
non-collaborative communication with project developers.
