#!/bin/sh
# tests for modelitem data, e.g. properties tags commands

BGO_DISABLE_PROJECT_DETECT=1
export BGO_DISABLE_PROJECT_DETECT

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo comment -c special -a me process/999/0x04 'comment with special context' | bin/bgo comment process/999/0x04 'default comment options' | bin/bgo comment -r -a me -c special process/999/0x04 | bin/bgo comment process/999/0x04 

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo comment -c special process/999/0x04 'comment with special context' | bin/bgo comment process/999/0x04

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo comment -a 'me, myself, and I' process/999/0x04 'comment with default context' | bin/bgo comment process/999/0x04 

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo comment process/999/0x04 'default comment' | bin/bgo comment process/999/0x04 

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo properties process/999/0x04 string=abcdef int=1234 float=1.01 hex=0xABCDEF | bin/bgo properties process/999/0x04

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo properties process/999/0x04 string=abcdef int=1234 float=1.01 hex=0xABCDEF | bin/bgo properties -r process/999/0x04 hex string | bin/bgo properties process/999/0x04

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo properties -j process/999/0x04 hash='{"a":[1,2,3],"b":[3,4,5]}' list='["a", "b", "c"]' | bin/bgo properties process/999/0x04

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo inspect process/999

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo tag process/999/0x04 do_stuff | bin/bgo inspect process/999/0x04

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo tag process/999/0x04 do_stuff | bin/bgo tag -r process/999/0x04 do_stuff | bin/bgo tag process/999/0x04

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo tag process/999/0x04 do_stuff  do_things do_whatever | bin/bgo tag -r process/999/0x04 do_stuff | bin/bgo tag process/999/0x04

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo inspect process/999/0x04

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo inspect process/999/address/0x04

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo inspect -j process/999/address/0x04

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo inspect -j process/999

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo inspect -jr process/999
