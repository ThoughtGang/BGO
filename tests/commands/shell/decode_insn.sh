#!/bin/sh
# Decode x86 instructions to BGO Instruction object

BGO_DISABLE_PROJECT_DETECT=1
export BGO_DISABLE_PROJECT_DETECT

 echo 'xor eax, eax
nop
int3
push eax
push ebx
push 0
call 0x010000
mov [ebp+4], eax' | bgo decode-insn
