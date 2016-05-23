#!/bin/sh
# test of env variables for managing plugins

BGO_PLUGINS=/tmp/plugins bin/bgo plugin-list '*A'
BGO_PLUGINS=/tmp/plugins bin/bgo plugin-list '*B'
BGO_PLUGINS=/tmp/plugins bin/bgo plugin-list '*B' '*A'
BGO_PLUGINS=/tmp/plugins bin/bgo plugin-info
BGO_PLUGINS=/tmp/plugins bin/bgo plugin-info 'Test A'
BGO_PLUGINS=/tmp/plugins bin/bgo plugin-info 'Test B'
