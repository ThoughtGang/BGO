#!/usr/bin/env ruby                                                             
# :title: Bgo::Commands::ModelItem
=begin rdoc
Utility methods for managing ModelItem objects in Commands. This is mostly
for instantiating ModelItems via object path, or for viewing ModelItem
object details.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

module Bgo
  module Commands

    def self.process_ident_or_path(state, ident)
      return nil if ! ident
      pid = Integer(ident) rescue nil
      pid ? state.process(pid) : state.item_at_obj_path(ident)
    end

    def self.file_ident_or_path(state, ident)
      return nil if ! ident
      f = state.file_find(ident)
      f || state.item_at_obj_path(ident)
    end

    # NOTE: This should probably not be used (targets should be specific)
    def self.target_ident_or_path(state, ident)
      return nil if ! ident
      pid = Integer(ident) rescue nil
      pid ? state.process(pid) : file_ident_or_path(ident)
      # TODO: add support for Buffer
    end

  end
end
