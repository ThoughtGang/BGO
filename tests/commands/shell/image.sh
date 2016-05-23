#!/bin/sh
BGO_DISABLE_PROJECT_DETECT=1
export BGO_DISABLE_PROJECT_DETECT

bin/bgo image-create -x "CC CC CC" | bin/bgo image

bin/bgo image-create -x "CC CC CC" | bin/bgo image

bin/bgo image-create -x "CC CC CC" | bin/bgo image

bin/bgo image-create -x "CC CC CC" |  bin/bgo image --full 0bd8a2794ea254b6c04eecd2fcbf1fa4fda439ae

bin/bgo image-create -x "CC CC CC" |  bin/bgo image -r 0bd8a2794ea254b6c04eecd2fcbf1fa4fda439ae | od -t x1

bin/bgo image-create -x "CC CC CC" |  bin/bgo image -c -i -x 0bd8a2794ea254b6c04eecd2fcbf1fa4fda439ae

bin/bgo image-create -x "CC CC CC" |  bin/bgo image -c -i 0bd8a2794ea254b6c04eecd2fcbf1fa4fda439ae

bin/bgo image-create -x "CC CC CC" |  bin/bgo image -i  0bd8a2794ea254b6c04eecd2fcbf1fa4fda439ae

bin/bgo image-create -x "CC CC CC" |  bin/bgo image -c --nop 0bd8a2794ea254b6c04eecd2fcbf1fa4fda439ae

bin/bgo project-create -n TheName -d 'a descr' | bin/bgo image-create -x "CC CC CC" | bin/bgo image --full 0bd8a2794ea254b6c04eecd2fcbf1fa4fda439ae
