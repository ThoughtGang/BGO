#!/bin/sh
# tests for plugin-list

./run_test.sh bin/bgo plugin-list
./run_test.sh bin/bgo plugin-list 'est*'
./run_test.sh bin/bgo plugin-list '*Test*'
./run_test.sh bin/bgo plugin-list 'T*est*'
./run_test.sh bin/bgo plugin-list '*est*'
./run_test.sh bin/bgo plugin-list "*"
./run_test.sh bin/bgo plugin-list '*'
BGO_PLUGINS=/tmp/plugins bin/bgo plugin-list '*A'
BGO_PLUGINS=/tmp/plugins bin/bgo plugin-list '*B'
BGO_PLUGINS=/tmp/plugins bin/bgo plugin-list '*B' '*A'
