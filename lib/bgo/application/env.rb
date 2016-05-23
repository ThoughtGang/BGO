#!/usr/bin/env ruby
# :title: Bgo::Env
=begin rdoc
BGO Environment variables
Copyright 2012 Thoughtgang <http://www.thoughtgang.org>

This module defines and documents the environment variables used by BGO.

If BGO_RUBYLIB is specified, it is applied to $: here.
=end 

module Bgo
  module Env

=begin rdoc
Location of BGO config files. This overrides settings in the default config 
files. Note that this is a directory, not a file; the config files must still
be named 'framework.yaml', 'plugins.yaml', etc.
=end
    CONFIG = 'BGO_CONFIG'

=begin rdoc
Path to the BGO Project to operate on. This is equivalent to using the -p
argument in a BGO Command.
=end
    PROJECT = 'BGO_PROJECT'

=begin rdoc
Do not attempt to detect whether the current directory is inside a BGO project.
This is will prevent a BGO project from being detected when the current 
directory is not in a BGO project, but is in a GIT repository.
=end
    NO_PROJECT_DETECT = 'BGO_DISABLE_PROJECT_DETECT'

=begin rdoc
Prevent use of Bgo::Git in Commands. This is used for testing, or if grit 
cannot be installed. The default behavior will fall back on streams of
JSON-encoded data.
=end
    NO_GIT = 'BGO_DISABLE_GIT'

=begin rdoc
Enable debug messages for Bgo::Git.
This will write error messaged from Bgo::Git to STDERR.
=end
#    GIT_DEBUG = 'BGO_GIT_DEBUG'

=begin rdoc
Paths for BGO plugins. This is a standard UNIX colon-delimited pathspec. These
paths will be added to the head of the BGO Plugin path list.
=end
    PLUGINS = 'BGO_PLUGINS'

=begin rdoc
List of blacklisted plugins. This is a colon-delimited list of Plugin names. The
names are matched against Plugin#canon_name. Note that the Plugin canonical name
is Plugin#name + '-' + Plugin#version. This must be an exact match for the
Plugin to be blacklisted; wildcards are not allowed.
=end
    PLUGIN_BLACKLIST = 'BGO_PLUGIN_BLACKLIST'

=begin rdoc
List of blacklisted plugins. This is a standard UNIX colon-delimited pathspec.
These paths are matched to plugin files (ruby modules) using String#end_with?.
=end
    PLUGIN_FILE_BLACKLIST = 'BGO_PLUGIN_FILE_BLACKLIST'

=begin rdoc
Enable debug messages for Plugin Manager.
This will write exceptions raised by plugins to $TG_PLUGIN_DEBUG_STREAM
(by default, STDERR).
=end
    PLUGIN_DEBUG = 'BGO_PLUGIN_DEBUG'

=begin rdoc
Paths for BGO commands. This is a standard UNIX colon-delimited pathspec. These
paths will be added to the head of the BGO Command path list.
=end
    COMMANDS = 'BGO_COMMANDS'

=begin rdoc
Ruby module path for BGO plugin. This is a standard UNIX colon-delimited 
pathspec. These paths are added to the head of the Ruby Library path ($:).
=end
    RUBYLIB = 'BGO_RUBYLIB'

=begin rdoc
Name of the BGO application user. This is used in comments and in the Git
repo config.
=end
    AUTHOR = 'BGO_AUTHOR_NAME'
=begin rdoc
Email of the BGO application user. This is used in the Git repo config.
=end
    AUTHOR_EMAIL = 'BGO_AUTHOR_EMAIL'


=begin rdoc
Return true if ENV contains name and the value of the ENV[name] is not empty.
=end
    def self.set?(name)
      ENV[name] && (! ENV[name].empty?)
    end

    if (set? RUBYLIB)
      ENV[RUBYLIB].split(':').reverse.each { |p| $:.unshift p }
    end
  end
end
