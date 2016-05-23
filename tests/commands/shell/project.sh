#!/bin/sh
# tests for bgo project creation. Be sure to run from /tmp

bgo project-create test stuff
bin/bgo project-create test stuff
bin/bgo project-create -n TheName -d 'a descr' test stuff
BGO_PROJECT='/tmp/t.bgo' bin/bgo project-create -n TheName -d 'a descr'
bin/bgo project-create -n TheName -d 'a descr' 
bin/bgo project-create -n TheName -d 'a descr' -p /tmp/t.bgo
bin/bgo project-create -n TheName -d 'a descr' | bin/bgo project
bin/bgo project-create -n TheName -d 'a descr' -p /tmp/t.bgo; bin/bgo project -p /tmp/t.bgo
bin/bgo help project
bin/bgo project-create -n TheName -d 'a descr' | bin/bgo project --stdin
bin/bgo project-create -n TheName -d 'a descr' | bin/bgo project --stdin -d
bin/bgo project-create -n TheName -d 'a descr' | bin/bgo project --stdin -n
bin/bgo project-create -n TheName -d 'a descr' | bin/bgo project --stdin -d 'some new stuff'
bin/bgo project-create -n TheName -d 'a descr' | bin/bgo project --stdin -d 
bin/bgo project-create -n TheName -d 'a descr' | bin/bgo project --stdin -d -n
bin/bgo project-create -n TheName -d 'a descr' | bin/bgo project --stdin -d this -n that
bin/bgo project-create -n TheName -d 'a descr' -p /tmp/t.bgo; bin/bgo project -p /tmp/t.bgo -d 'some stuff'
bin/bgo project-create -n TheName -d 'a descr' -p /tmp/t.bgo; bin/bgo project -p /tmp/t.bgo -d 'some stuff';  bin/bgo project -p /tmp/t.bgo
rm -rf /tmp/t.bgo/
bin/bgo project-create -n TheName -d 'a descr' -p /tmp/t.bgo; bin/bgo project -p /tmp/t.bgo -d 'some stuff';  bin/bgo project -p /tmp/t.bgo -d 'new descr'
bin/bgo project-create -n TheName -d 'a descr' -p /tmp/t.bgo; bin/bgo project -p /tmp/t.bgo -d 'some stuff';  bin/bgo project -p /tmp/t.bgo -d 
bin/bgo project-create -n TheName -d 'a descr' -p /tmp/t.bgo; bin/bgo project -p /tmp/t.bgo -d 'some stuff';  bin/bgo project -p /tmp/t.bgo -d 'new descr' --stdout
bin/bgo project -p /tmp/t.bgo -d 'new descr' --stdout
