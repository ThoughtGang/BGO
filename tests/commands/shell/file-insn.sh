#!/bin/sh
# test creation of instructions in a file

bin/bgo image-create -x '90 CC 31 C0' | \
bin/bgo file-create -i f94a4122ac0236375afa30967bf761849b209d38 /tmp/a.out | \
bin/bgo section-create -o 0 -s 4 -n .text -i 1 file/^tmp^a.out | \
bin/bgo address-create -o 0 -s 1 file/^tmp^a.out | \
bin/bgo address-create -o 1 -s 1 file/^tmp^a.out | \
bin/bgo address-create -o 2 -s 2 file/^tmp^a.out | \
bin/bgo arch-edit -a x86 -l file/^tmp^a.out 1 | \
bin/bgo insn-create file/^tmp^a.out 0 nop | \
bin/bgo insn-create file/^tmp^a.out 1 int3 | \
bin/bgo insn-create file/^tmp^a.out 2 'xor %eax %eax' #| \

