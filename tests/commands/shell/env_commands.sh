#!/bin/sh
# test of BGO environment variables for managing Commands.

BGO_DISABLE_PROJECT_DETECT=1
export BGO_DISABLE_PROJECT_DETECT
BGO_COMMANDS='/tmp' ./run_test.sh bin/bgo echo this is a test
BGO_COMMANDS='/tmp' ./run_test.sh bin/bgo help
BGO_COMMANDS='/tmp/commands' ./run_test.sh bin/bgo test this
BGO_COMMANDS='/tmp/commands' ./run_test.sh bin/bgo help test
BGO_COMMANDS='/tmp/commands' ./run_test.sh bin/bgo help
