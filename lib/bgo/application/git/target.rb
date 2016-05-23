#!/usr/bin/env ruby
# :title: Bgo::Git::Target
=begin rdoc
BGO Target object in Git-DB.

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

# TODO: wrappers for ref/symtab accessors that set @self_dirty
# NOTE: these need some mechanism for notifying parent (target) when dirty

module Bgo
  module Git

    module TargetClass
      FILE_REF = 'references'
      FILE_SYM = 'symtab' 
      
      def target_load(repo, path)
        h = {}
        repo.chdir do
          h[:scope] = load_json(path, FILE_SYM)
          h[:references] = load_json(path, FILE_REF)
        end
        h
      end
    end

    module TargetObject

      #FILE_BLK = TargetClass::FILE_BLK
      FILE_REF = TargetClass::FILE_REF
      FILE_SYM = TargetClass::FILE_SYM

      def target_update
        repo.chdir do
          write_repo_file( File.join(repo_path, FILE_SYM), 
                           @scope.to_hash.to_json + "\n" )
          write_repo_file( File.join(repo_path, FILE_REF), 
                           @references.to_hash.to_json + "\n" )
        end
      end
    end

  end
end
