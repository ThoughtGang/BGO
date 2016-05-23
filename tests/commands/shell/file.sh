#!/bin/sh
# tests for file creation

# note: copy something (like /bin/ls) to /tmp/t.bin before using

BGO_DISABLE_PROJECT_DETECT=1
export BGO_DISABLE_PROJECT_DETECT

bin/bgo file-create /tmp/t.bin 

bin/bgo file-create /tmp/t.bin | bin/bgo file

bin/bgo file-create /tmp/t.bin | bin/bgo file /tmp/t.bin

bin/bgo file-create /tmp/t.bin | bin/bgo file -l file/^tmp^t.bin

bin/bgo file-create -c 'cli test' /tmp/t.bin | bin/bgo file --full '^tmp^t.bin'

bin/bgo image-create -x 'CC CC CC CC' | bin/bgo file-create -i 24ce0f78e5d6172a5c6d50b83d6104aa4144b317 '/tmp/a.out'  | bin/bgo file --full '^tmp^a.out'

bin/bgo image-create -x 'CC CC CC CC' | bin/bgo file-create -i 24ce0f78e5d6172a5c6d50b83d6104aa4144b317 /tmp/a.out | bin/bgo file-create -P file/^tmp^a.out t.bin | bin/bgo file --full file/^tmp^a.out

bin/bgo image-create -x 'CC CC CC CC' | bin/bgo file-create -i 24ce0f78e5d6172a5c6d50b83d6104aa4144b317 '/tmp/a.out' | bin/bgo file-create -P '^tmp^a.out' -o 1 -s 2 't.bin' | bin/bgo file --full -x 't.bin'

bin/bgo image-create -x 'CC CC CC CC' | bin/bgo file-create -i 24ce0f78e5d6172a5c6d50b83d6104aa4144b317 '/tmp/a.out' | bin/bgo file-create -P '^tmp^a.out' -o 1 -s 2 't.bin' | bin/bgo file-edit -c 'inner file' 't.bin' | bin/bgo file --full 't.bin'

bin/bgo image-create -x 'CC CC CC CC' | bin/bgo file-create -i 24ce0f78e5d6172a5c6d50b83d6104aa4144b317 '/tmp/a.out' | bin/bgo file-create -P '^tmp^a.out' -o 1 -s 2 't.bin' | bin/bgo file-edit -c 'inner file' 't.bin' | bin/bgo file --full file/^tmp^a.out/file/t.bin

bin/bgo image-create -x 'CC CC CC CC' | bin/bgo file-create -i 24ce0f78e5d6172a5c6d50b83d6104aa4144b317 '/tmp/a.out' | bin/bgo file-create -P '^tmp^a.out' -o 1 -s 2 't.bin' | bin/bgo file-delete file/^tmp^a.out/file/t.bin | bin/bgo file --full file/^tmp^a.out

bin/bgo image-create -x 'CC CC CC CC' | bin/bgo file-create -i 24ce0f78e5d6172a5c6d50b83d6104aa4144b317 '/tmp/a.out' | bin/bgo file-create -P '^tmp^a.out' -o 1 -s 2 't.bin' | bin/bgo file-delete file/^tmp^a.out/file/t.bin | bin/bgo file --full -x file/^tmp^a.out

bin/bgo image-create -x 'CC CC CC CC' | bin/bgo file-create -i 24ce0f78e5d6172a5c6d50b83d6104aa4144b317 '/tmp/a.out' | bin/bgo file-create -P '^tmp^a.out' -o 1 -s 2 't.bin' | bin/bgo file-delete file/^tmp^a.out | bin/bgo file
