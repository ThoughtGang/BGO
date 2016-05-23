#!/bin/sh
# basic test of help commands

BGO_COMMANDS='/tmp' ./run_test.sh bin/bgo help
BGO_COMMANDS='/tmp/commands' ./run_test.sh bin/bgo help test
BGO_COMMANDS='/tmp/commands' ./run_test.sh bin/bgo help
BGO_CONFIG='/tmp/commands' ./run_test.sh bin/bgo help
