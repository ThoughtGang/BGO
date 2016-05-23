#!/bin/sh
# test of env variables for managing BGO config

BGO_DISABLE_PROJECT_DETECT=1
export BGO_DISABLE_PROJECT_DETECT

BGO_CONFIG='/tmp/commands' ./run_test.sh bin/bgo help
BGO_CONFIG=/tmp/commands ./run_test.sh bin/bgo plugin-list
