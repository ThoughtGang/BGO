#!/bin/sh
# test of env variables managing project detection

BGO_DISABLE_PROJECT_DETECT=1 
export BGO_DISABLE_PROJECT_DETECT
bin/bgo image-create -x "CC CC CC" | bin/bgo image
