#!/bin/sh
# tests for bgo plugin info command

BGO_PLUGINS=/tmp/plugins bin/bgo plugin-info
BGO_PLUGINS=/tmp/plugins bin/bgo plugin-info 'Test A'
BGO_PLUGINS=/tmp/plugins bin/bgo plugin-info 'Test B'
