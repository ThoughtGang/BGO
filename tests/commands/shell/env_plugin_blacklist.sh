#!/bin/sh
# test for env variables managing plugin blacklist
# NOTE: this is used after copying the test plugin to /tmp

BGO_PLUGIN_FILE_BLACKLIST='/tmp/plugins/test.rb' BGO_CONFIG=/tmp/commands ./run_test.sh bin/bgo plugin-list
BGO_PLUGIN_FILE_BLACKLIST='test.rb' BGO_CONFIG=/tmp/commands ./run_test.sh bin/bgo plugin-list
BGO_PLUGIN_FILE_BLACKLIST='plugins/test.rb' BGO_CONFIG=/tmp/commands ./run_test.sh bin/bgo plugin-list
BGO_PLUGIN_FILE_BLACKLIST='test/plugins/test.rb' BGO_CONFIG=/tmp/commands ./run_test.sh bin/bgo plugin-list
BGO_PLUGIN_FILE_BLACKLIST='tmp/plugins/test.rb' BGO_CONFIG=/tmp/commands ./run_test.sh bin/bgo plugin-list
BGO_PLUGIN_BLACKLIST='Test A' BGO_CONFIG=/tmp/commands ./run_test.sh bin/bgo plugin-list
BGO_PLUGIN_BLACKLIST='Test A-1.0' BGO_CONFIG=/tmp/commands ./run_test.sh bin/bgo plugin-list
BGO_PLUGIN_BLACKLIST='Test A-1.0-pre' BGO_CONFIG=/tmp/commands ./run_test.sh bin/bgo plugin-list
BGO_PLUGIN_BLACKLIST='Test A-1.0.1-a' BGO_CONFIG=/tmp/commands ./run_test.sh bin/bgo plugin-list
