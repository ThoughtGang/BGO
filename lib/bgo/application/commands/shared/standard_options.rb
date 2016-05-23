#!/usr/bin/env ruby
=begin rdoc
Standard options parsing methods for BGO commands.

Copyright 2012 Thoughtgang <http://www.thoughtgang.org>
=end

# TODO: should -- enable stdin AND stdout?
require 'bgo/application/env'

require 'bgo/project'

require 'optparse'
require 'ostruct'

module Bgo
  module Commands

=begin rdoc
Add standard options to the OptionsParser 'opts'. Fill 'options' structure
with defaults for these settings.
=end
    def self.standard_options(options, opts)
      # read project/data in JSON from STDIN
      options.stdin = false

      # write project/data in JSON to STDOUT
      options.stdout = false

      opts.on( '--stdin' )    {options.stdin = options.explicit_stdin = true;
                               options.project_detect = false}
      opts.on( '--no-stdin' ) {options.stdin = options.explicit_stdin = false}
      opts.on( '--' )         {options.stdin = options.explicit_stdin = true;
                               options.project_detect = false}
      opts.on( '--no-stdout' ){options.stdout = options.explicit_stdout = false}
      opts.on( '--cron' )     {options.stdin = options.explicit_stdin = false;
                               options.project_detect = false}
      opts.on( '--nop' ) { }
    end

=begin rdoc
Return the help string for standard options
=end
    def self.standard_options_help
"Standard BGO command options:
  --, --stdin             Read JSON-encoded input data from STDIN [default]
  --stdout                Write JSON-encoded data to STDOUT [default]
  --nop                   Do nothing. This is a no-op argument"
    end

  end
end
