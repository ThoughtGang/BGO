#!/bin/sh
# tests for process create etc

BGO_DISABLE_PROJECT_DETECT=1
export BGO_DISABLE_PROJECT_DETECT

bin/bgo process-create -i 999 -f ^bin^ls -c 'test process' /bin/ls stuff | bin/bgo process --full 999

bin/bgo process-create -i 999 -f ^bin^ls -c 'test process' /bin/ls stuff | bin/bgo process -l process/999

bin/bgo process-create -i 999 -f ^bin^ls -c 'test process' /bin/ls stuff | bin/bgo process --full 999

bin/bgo process-create -i 999 -f ^bin^ls -c 'test process' /bin/ls stuff | bin/bgo process -l process/999

bin/bgo process-create -i 999 -f ^bin^ls -c 'test process' /bin/ls stuff | bin/bgo arch-edit -a "MMIX" -b process/999 | bin/bgo process --full process/999

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo process-delete 999 | bin/bgo process -l

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' process/999 | bin/bgo process-delete process/999 | bin/bgo process -l

bin/bgo process-create -i 999 -f ^bin^ls /bin/ls stuff | bin/bgo process-edit -f /bin/ls -C 'ls -l' -c 'stuff' 999 | bin/bgo process-delete 999 | bin/bgo process -l

