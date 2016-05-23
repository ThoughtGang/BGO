#!/usr/bin/env ruby
# :title: BGO
=begin rdoc
=Binary Generic Object Framework
<i>Copyright 2013 Thoughtgang <http://www.thoughtgang.org></i>
=end

module Bgo
  autoload :Address, 'bgo/address.rb'
  autoload :AddressContainer, 'bgo/address_container.rb'
  autoload :AddressRef, 'bgo/address.rb'
  autoload :ArchInfo, 'bgo/arch_info.rb'
  autoload :AuthoredComments, 'bgo/comment.rb'
  autoload :Block, 'bgo/block.rb'
  autoload :ByteContainer, 'bgo/byte_container.rb'
  autoload :Comment, 'bgo/comment.rb'
  autoload :DisasmTask, 'bgo/disasm.rb'
  autoload :Disassemble, 'bgo/disasm.rb'
  autoload :Image, 'bgo/image.rb'
  autoload :ImageChangeset, 'bgo/image_changeset.rb'
  autoload :ImageRevision, 'bgo/image_revision.rb'
  autoload :Instruction, 'bgo/instruction.rb'
  autoload :Map, 'bgo/map.rb'
  autoload :ModelItemClass, 'bgo/model_item.rb'
  autoload :ModelItemObject, 'bgo/model_item.rb'
  #autoload :ModelItemFactory, 'bgo/model_item.rb'
  autoload :Opcode, 'bgo/instruction.rb'
  autoload :Operand, 'bgo/instruction.rb'
  autoload :Packet, 'bgo/packet.rb'
  autoload :PatchedImage, 'bgo/patched_image.rb'
  autoload :Process, 'bgo/process.rb'
  autoload :Project, 'bgo/project.rb'
  autoload :Reference, 'bgo/reference.rb'
  autoload :References, 'bgo/reference.rb'
  autoload :RefItem, 'bgo/reference.rb'
  autoload :Scope, 'bgo/scope.rb'
  autoload :Section, 'bgo/section.rb'
  autoload :SectionedTargetObject, 'bgo/sectioned_target.rb'
  autoload :Symbol, 'bgo/symbol.rb'
  autoload :TagList, 'bgo/tag.rb'
  autoload :TagRegistry, 'bgo/tag.rb'
  autoload :TargetClass, 'bgo/target.rb'
  autoload :TargetFile, 'bgo/file.rb'
  autoload :TargetObject, 'bgo/target.rb'
  autoload :VirtualImage, 'bgo/image.rb'
end
