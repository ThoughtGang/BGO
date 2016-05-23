#!/bin/sh
# test file section creation and reporting
BGO_DISABLE_PROJECT_DETECT=1
export BGO_DISABLE_PROJECT_DETECT

bin/bgo image-create -x 'CC CC CC CC CC CC CC CC' | bin/bgo file-create -i a01baa79948cdcc0d928ab67eff004a3ece60b5c '/tmp/a.out' | bin/bgo file-create -P '^tmp^a.out' -o 1 -s 2 't.bin' | bin/bgo section-create -o 2 -s 4 -n test -i 123 '/tmp/a.out' | bin/bgo section file/^tmp^a.out

bin/bgo image-create -x 'CC CC CC CC CC CC CC CC' | bin/bgo file-create -i a01baa79948cdcc0d928ab67eff004a3ece60b5c '/tmp/a.out' | bin/bgo file-create -P '^tmp^a.out' -o 1 -s 2 't.bin' | bin/bgo section-create -o 2 -s 4 -n test -i 123 '/tmp/a.out' | bin/bgo section --full file/^tmp^a.out/section/123

bin/bgo image-create -x 'CC CC CC CC CC CC CC CC' | bin/bgo file-create -i a01baa79948cdcc0d928ab67eff004a3ece60b5c '/tmp/a.out' | bin/bgo file-create -P '^tmp^a.out' -o 1 -s 2 't.bin' | bin/bgo section-create -o 2 -s 4 -n test -i 123 '/tmp/a.out' | bin/bgo section -x file/^tmp^a.out/section/123

bin/bgo image-create -x 'CC CC CC CC CC CC CC CC' | bin/bgo file-create -i a01baa79948cdcc0d928ab67eff004a3ece60b5c '/tmp/a.out' | bin/bgo file-create -P '^tmp^a.out' -o 1 -s 2 't.bin' | bin/bgo section-create -o 2 -s 4 -n test -i 123 '/tmp/a.out' | bin/bgo section-edit -n 'nombre' -c 'custom comment' file/^tmp^a.out/section/123 | bin/bgo section --full file/^tmp^a.out/section/123

bin/bgo image-create -x 'CC CC CC CC CC CC CC CC' | bin/bgo file-create -i a01baa79948cdcc0d928ab67eff004a3ece60b5c '/tmp/a.out' | bin/bgo file-create -P '^tmp^a.out' -o 1 -s 2 't.bin' | bin/bgo section-create -o 2 -s 4 -n test -i 123 '/tmp/a.out' | bin/bgo section-delete file/^tmp^a.out/section/123 | bin/bgo section --full file/^tmp^a.out

