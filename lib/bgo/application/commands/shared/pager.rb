#!/usr/bin/env ruby
# :title: Bgo::Commands::Pager
=begin rdoc
BGO command facility to run STDOUT through ENV['PAGER']

Adapted from http://nex-3.com/posts/73-git-style-automatic-paging-in-ruby .
Note that this overrides PAGER with BGO_PAGER, does not default to less, and 
does not page STDERR.
=end

require 'rbconfig'

module Bgo
  module Commands

=begin rdoc
Utility methods to redirect STDOUT to a pager program started via fork/exec.
=end
    module Pager

=begin rdoc
Redirect STDOUT to the pager in $BGO_PAGER.
=end
      def redirect
        # do not page if we are in windows
        return if RbConfig::CONFIG['host_os'] =~ /mswin|mingw/

        # do not page if not a TTY
        return if not STDOUT.tty?

        # check for $BGO_PAGER
        pager = ENV['BGO_PAGER']
        # if not present, fall-through to $PAGER
        # TODO: fall-through to less when $PAGER is nil?
        pager = ENV['PAGER'] if not pager
        # return if pager has been set to an empty string ('') or 'cat'
        return if (pager.empty?) || pager == 'cat'

        pin, pout = IO.pipe
        if Kernel.fork    # parent : this is now pager
          STDIN.reopen(pin)
          pin.close
          pout.close
          Kernel.select [STDIN]
          exec pager rescue exec "/bin/sh", "-c", pager
        else              # child : this is now bgo
          STDOUT.reopen(pout)
          pin.close
          pout.close
        end
      end

    end

  end
end
