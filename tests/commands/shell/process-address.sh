#!/bin/sh
# commands for testing process address creation

BGO_DISABLE_PROJECT_DETECT=1
export BGO_DISABLE_PROJECT_DETECT

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 process/999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo address-delete process/999/0x04 | bin/bgo address --full process/999

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo map-create -s 100 process/999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 /process/999 | bin/bgo address-edit -c ooogy process/999/0x04 | bin/bgo address --full process/999/0x04
bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' process/999 | bin/bgo map-create -s 100 process/999 | bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | bin/bgo address-create -v 0x04 -s 16 process/999 | bin/bgo address-edit -c ooogy process/999/0x04 | bin/bgo address --full process/999/map/0
