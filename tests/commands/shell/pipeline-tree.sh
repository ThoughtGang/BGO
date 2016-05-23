#!/bin/sh
BGO_DISABLE_PROJECT_DETECT=1
export BGO_DISABLE_PROJECT_DETECT
bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | \
	bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | \
	bin/bgo map-create -s 100 process/999 | \
	bin/bgo map-edit -f 'rwx' -c 'oog' process/999/map/0 | \
	bin/bgo address-create -a 0 -s 2 process/999 | \
	bin/bgo address-create -a 2 -s 1 process/999 | \
	bin/bgo address-create -a 3 -s 1 process/999 | \
	bin/bgo address-create -a 0x04 -s 16 process/999 | \
	bin/bgo address-edit -c 'blah' process/999/map/0/address/0x04 | \
	bin/bgo block-create process/999 2 2 | \
	bin/bgo pipeline-tree
