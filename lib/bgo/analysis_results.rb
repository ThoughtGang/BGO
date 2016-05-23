#!/usr/bin/env ruby                                                             
# :title: Bgo::AnalysisResults
=begin rdoc
BGO AnalysisResults object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end


module Bgo

=begin rdoc
Generic results-of-analysis object.
Specific Analysis plugins are expected to subclass this object in order to
store and serialize specific results.
=end
  class AnalysisResults

    # TODO: suitable base class (contents, name, plugin)

=begin rdoc
Identity to use as a primary key when storing this object in a Hash. This
can be the name of the Plugin providing the results (e.g. 'LLVM Generator'), 
the name of the class subclassing AnalysisResults (e.g. 'BasicBlockResults'),
or a custom String that identifies both the results type and any additional
identifying information (timestamp, sequence number, parameters, etc).
=end
    attr_reader :ident
  end

end
