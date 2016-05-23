#!/usr/bin/env ruby
# Metadata for x86 CPU registers
# Copyright 2010 Thoughtgang <http://www.thoughtgang.org>

module Bgo
  module Plugins
    module Isa
      module X86
        module Metadata

# if mask is nil. use lower n bytes of virtual register
=begin rdoc
Metadata for all CPU registers.
Each entry is a Hash with the following keys:
  :id: ID of physical register. 
  :size: Size of register in bytes.
  :mask: The mask applied to the physical register to get this register.
  :type: Type of register.
  :purpose: General use of the register in code.
The mnemonic or name of the register, in lowercade and stripped of all i
prefixes, is used as the key. Thus 'eax', 'Eax', 'EAX', and '%eax' would
all have the key 'eax'.

In the x86 instruction sets, multiple virtual registers are aliased to a
physical register. For example, Register 1 (%RAX) has the following
aliases:

  :al: byte 0 (%RAX & 0xFF)
  :ah: byte 1 ((%RAX & 0xFF00) >> 1)
  :ax: bytes 0-1 (%RAX & 0xFFFF)
  :eax: bytes 0-3 (%RAX & (2**32 - 1))
  :rax: bytes 0-7 (%RAX & (2**64 - 1))

In addition, the MMX registers (%MM0 - %MM7) use the same physical registers 
as the FPU registers (%ST(0) - %ST(7)).

When emulating CPU behavior or performing data-flow analysis, it is important
to keep track of the register ID, as well as its size and mask.

Note: When mask is nil, then the lower :size bytes of the physical register
are used. A 2-byte register would thus have a mask of 0xFFFF, a four-byte
register would have (2**32 - 1), and so on.
=end

REGISTERS = {

  # General-purpose byte
  'al' => { :id => 1, :size => 1, :mask => 0xFF, :type => Bgo::Register::GEN, 
            :purpose => [] },
  'cl' => { :id => 2, :size => 1, :mask => 0xFF, :type => Bgo::Register::GEN, 
            :purpose => [] },
  'dl' => { :id => 3, :size => 1, :mask => 0xFF, :type => Bgo::Register::GEN, 
            :purpose => [] },
  'bl' => { :id => 4, :size => 1, :mask => 0xFF, :type => Bgo::Register::GEN, 
            :purpose => [] },
  'ah' => { :id => 1, :size => 1, :mask => 0xFF00, :type => Bgo::Register::GEN, 
            :purpose => [] },
  'ch' => { :id => 2, :size => 1, :mask => 0xFF00, :type => Bgo::Register::GEN, 
            :purpose => [] },
  'dh' => { :id => 3, :size => 1, :mask => 0xFF00, :type => Bgo::Register::GEN, 
            :purpose => [] },
  'bh' => { :id => 4, :size => 1, :mask => 0xFF00, :type => Bgo::Register::GEN, 
            :purpose => [] },
  
  # ...x86-64 extensions...
  
  'spl' => { :id => 5, :size => 1, :mask => 0xFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'bpl' => { :id => 6, :size => 1, :mask => 0xFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'sil' => { :id => 7, :size => 1, :mask => 0xFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'dil' => { :id => 8, :size => 1, :mask => 0xFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r8b' => { :id => 9, :size => 1, :mask => 0xFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r9b' => { :id => 10, :size => 1, :mask => 0xFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r10b' => { :id => 11, :size => 1, :mask => 0xFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r11b' => { :id => 12, :size => 1, :mask => 0xFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r12b' => { :id => 13, :size => 1, :mask => 0xFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r13b' => { :id => 14, :size => 1, :mask => 0xFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r14b' => { :id => 15, :size => 1, :mask => 0xFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r15b' => { :id => 16, :size => 1, :mask => 0xFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  
  # General-purpose (machine) half-word (2-byte or Windows/Intel WORD)
  'ax' => { :id => 1, :size => 2, :mask => 0xFFFF, :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::RET, Bgo::Register::ACC ] },
  'cx' => { :id => 2, :size => 2, :mask => 0xFFFF, :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::COUNT ] },
  'dx' => { :id => 3, :size => 2, :mask => 0xFFFF, :type => Bgo::Register::GEN, 
            :purpose => [] },
  'bx' => { :id => 4, :size => 2, :mask => 0xFFFF, :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::BASE ] },
  'sp' => { :id => 5, :size => 2, :mask => 0xFFFF, :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::STACK ] },
  'bp' => { :id => 6, :size => 2, :mask => 0xFFFF, :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::FRAME] },
  'si' => { :id => 7, :size => 2, :mask => 0xFFFF, :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::SOURCE ] },
  'di' => { :id => 8, :size => 2, :mask => 0xFFFF, :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::DEST ] },
  
  # ...x86-64 extensions...
  'r8w' => { :id => 9, :size => 2, :mask => 0xFFFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r9w' => { :id => 10, :size => 2, :mask => 0xFFFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r10w' => { :id => 11, :size => 2, :mask => 0xFFFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r11w' => { :id => 12, :size => 2, :mask => 0xFFFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r12w' => { :id => 13, :size => 2, :mask => 0xFFFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r13w' => { :id => 14, :size => 2, :mask => 0xFFFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r14w' => { :id => 15, :size => 2, :mask => 0xFFFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r15w' => { :id => 16, :size => 2, :mask => 0xFFFF, 
            :type => Bgo::Register::GEN, :purpose => [] },
  
  # General-purpose (machine) word (4-byte or Windows/Intel DWORD)
  'eax' => { :id => 1, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::RET, Bgo::Register::ACC ] },
  'ecx' => { :id => 2, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::COUNT ] },
  'edx' => { :id => 3, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [] },
  'ebx' => { :id => 4, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::BASE ] },
  'esp' => { :id => 5, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::STACK ] },
  'ebp' => { :id => 6, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::FRAME ] },
  'esi' => { :id => 7, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::SOURCE ] },
  'edi' => { :id => 8, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::DEST ] },
  
  # ...x86-64 extensions...
  'r8d' => { :id => 9, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r9d' => { :id => 10, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r10d' => { :id => 11, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r11d' => { :id => 12, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r12d' => { :id => 13, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r13d' => { :id => 14, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r14d' => { :id => 15, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r15d' => { :id => 16, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  
  # General-purpose (machine) double-word (8-byte or Windows/Intel QWORD) 
  'rax' => { :id => 1, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::RET, Bgo::Register::ACC ] },
  'rcx' => { :id => 2, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [Bgo::Register::COUNT ] },
  'rdx' => { :id => 3, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [] },
  'rbx' => { :id => 4, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::BASE ] },
  'rsp' => { :id => 5, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::STACK ] },
  'rbp' => { :id => 6, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::FRAME ] },
  'rsi' => { :id => 7, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::SOURCE ] },
  'rdi' => { :id => 8, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, 
            :purpose => [ Bgo::Register::DEST ] },
  
  # ...x86-64 extensions...
  'r8' => { :id => 9, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r9' => { :id => 10, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r10' => { :id => 11, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r11' => { :id => 12, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r12' => { :id => 13, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r13' => { :id => 14, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r14' => { :id => 15, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  'r15' => { :id => 16, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::GEN, :purpose => [] },
  
  # MMX  registers
  'mm0' => { :id => 17, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::SIMD, :purpose => [] },
  'mm1' => { :id => 18, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::SIMD, :purpose => [] },
  'mm2' => { :id => 19, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::SIMD, :purpose => [] },
  'mm3' => { :id => 20, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::SIMD, :purpose => [] },
  'mm4' => { :id => 21, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::SIMD, :purpose => [] },
  'mm5' => { :id => 22, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::SIMD, :purpose => [] },
  'mm6' => { :id => 23, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::SIMD, :purpose => [] },
  'mm7' => { :id => 24, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::SIMD, :purpose => [] },
  
  # SSE registers
  'xmm0' => { :id => 25, :size => 16, :mask => (2**128 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  'xmm1' => { :id => 26, :size => 16, :mask => (2**128 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  'xmm2' => { :id => 27, :size => 16, :mask => (2**128 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  'xmm3' => { :id => 28, :size => 16, :mask => (2**128 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  'xmm4' => { :id => 29, :size => 16, :mask => (2**128 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  'xmm5' => { :id => 30, :size => 16, :mask => (2**128 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  'xmm6' => { :id => 31, :size => 16, :mask => (2**128 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  'xmm7' => { :id => 32, :size => 16, :mask => (2**128 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  'mxcsr' => { :id => 61, :size => 4, :mask => (2**128 - 1), 
            :type => Bgo::Register::FLAGS, :purpose => [] },
  
  # AVX registers
  'ymm0' => { :id => 25, :size => 32, :mask => (2**256 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  'ymm1' => { :id => 26, :size => 32, :mask => (2**256 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  'ymm2' => { :id => 27, :size => 32, :mask => (2**256 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  'ymm3' => { :id => 28, :size => 32, :mask => (2**256 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  'ymm4' => { :id => 29, :size => 32, :mask => (2**256 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  'ymm5' => { :id => 30, :size => 32, :mask => (2**256 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  'ymm6' => { :id => 31, :size => 32, :mask => (2**256 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  'ymm7' => { :id => 32, :size => 32, :mask => (2**256 - 1),
            :type => Bgo::Register::SIMD, :purpose => [] },
  # FPU registers
  # TODO: handle FPU stack somehow?
  'st(0)' => { :id => 17, :size => 10, :mask => (2**80 - 1), 
            :type => Bgo::Register::FPU, :purpose => [] },
  'st(1)' => { :id => 18, :size => 10, :mask => (2**80 - 1), 
            :type => Bgo::Register::FPU, :purpose => [] },
  'st(2)' => { :id => 19, :size => 10, :mask => (2**80 - 1), 
            :type => Bgo::Register::FPU, :purpose => [] },
  'st(3)' => { :id => 20, :size => 10, :mask => (2**80 - 1), 
            :type => Bgo::Register::FPU, :purpose => [] },
  'st(4)' => { :id => 21, :size => 10, :mask => (2**80 - 1), 
            :type => Bgo::Register::FPU, :purpose => [] },
  'st(5)' => { :id => 22, :size => 10, :mask => (2**80 - 1), 
            :type => Bgo::Register::FPU, :purpose => [] },
  'st(6)' => { :id => 23, :size => 10, :mask => (2**80 - 1), 
            :type => Bgo::Register::FPU, :purpose => [] },
  'st(7)' => { :id => 24, :size => 10, :mask => (2**80 - 1), 
            :type => Bgo::Register::FPU, :purpose => [] },
  
  # Control registers
  'cr0' => { :id => 33, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::CTL, :purpose => [] },
  'cr1' => { :id => 34, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::CTL, :purpose => [] },
  'cr2' => { :id => 35, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::CTL, :purpose => [] },
  'cr3' => { :id => 36, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::CTL, :purpose => [] },
  'cr4' => { :id => 37, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::CTL, :purpose => [] },
  'cr5' => { :id => 38, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::CTL, :purpose => [] },
  'cr6' => { :id => 39, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::CTL, :purpose => [] },
  'cr7' => { :id => 40, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::CTL, :purpose => [] },
  
  # Debug registers
  'dr0' => { :id => 41, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::DBG, :purpose => [] },
  'dr1' => { :id => 42, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::DBG, :purpose => [] },
  'dr2' => { :id => 43, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::DBG, :purpose => [] },
  'dr3' => { :id => 44, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::DBG, :purpose => [] },
  'dr4' => { :id => 45, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::DBG, :purpose => [] },
  'dr5' => { :id => 46, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::DBG, :purpose => [] },
  'dr6' => { :id => 47, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::DBG, :purpose => [] },
  'dr7' => { :id => 48, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::DBG, :purpose => [] },
  
  # Segment registers
  'cs' => { :id => 49, :size => 2, :mask => 0xFFFF, 
            :type => Bgo::Register::GEN, :purpose => [ Bgo::Register::SEG ] },
  'ds' => { :id => 50, :size => 2, :mask => 0xFFFF, 
            :type => Bgo::Register::GEN, :purpose => [ Bgo::Register::SEG ] },
  'ss' => { :id => 51, :size => 2, :mask => 0xFFFF, 
            :type => Bgo::Register::GEN, :purpose => [ Bgo::Register::SEG ] },
  'es' => { :id => 52, :size => 2, :mask => 0xFFFF, 
            :type => Bgo::Register::GEN, :purpose => [ Bgo::Register::SEG ] },
  'fs' => { :id => 53, :size => 2, :mask => 0xFFFF, 
            :type => Bgo::Register::GEN, :purpose => [ Bgo::Register::SEG ] },
  'gs' => { :id => 54, :size => 2, :mask => 0xFFFF, 
            :type => Bgo::Register::GEN, :purpose => [ Bgo::Register::SEG ] },
  
  # Instruction pointer
  'eip' => { :id => 55, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::PC, :purpose => [] },
  'rip' => { :id => 55, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::PC, :purpose => [] },

  # Condition codes
  'eflags' => { :id => 56, :size => 4, :mask => (2**32 - 1), 
            :type => Bgo::Register::FLAGS, :purpose => [] },
  'rflags' => { :id => 56, :size => 8, :mask => (2**64 - 1), 
            :type => Bgo::Register::FLAGS, :purpose => [] },
  
  # Task and Descriptor registers
  'gdtr' => { :id => 57, :size => 6, :mask => (2**48 - 1), 
            :type => Bgo::Register::MEM, :purpose => [] },
  'ldtr' => { :id => 58, :size => 6, :mask => (2**48 - 1), 
            :type => Bgo::Register::MEM, :purpose => [] },
  'idtr' => { :id => 59, :size => 6, :mask => (2**48 - 1), 
            :type => Bgo::Register::MEM, :purpose => [] },
  'tr' => { :id => 60, :size => 6, :mask => (2**48 - 1), 
            :type => Bgo::Register::TASK, :purpose => [] }
}

        end
      end
    end
  end
end
