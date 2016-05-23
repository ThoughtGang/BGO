#!/usr/bin/env ruby
# :title: Bgo::Commands::Revision
=begin rdoc
BGO command to list and examine Revision objects in an AddressContainer

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'bgo/application/command'
require 'bgo/application/commands/shared/data_model_options'
require 'bgo/application/commands/shared/pipeline'
require 'bgo/application/commands/shared/standard_options'

module Bgo
  module Commands

=begin rdoc
A command to show Revision objects in an AddressContainer.
=end
    class RevisionCommand < Application::Command
# ----------------------------------------------------------------------
      disable_plugins
      end_pipeline
      summary 'List or view BGO Revision objects'
      usage "#{Commands.data_model_usage} [-abceil] [--full] OBJPATH [...]"
      help "List/View AddressContainer Revisions in a Project or from STDIN.
Category: porcelain

Options:
  -a, --addresses      Show address objects in Revision
  -b, --changed-bytes  Show changed bytes in Revision
  -c, --comment        Show Revision comment
  -e, --is_empty       Show if this Revision is the Empty/base revision
  -i, --ident          Show Revision ident
  -l, --list           List all Revisions for object (a Map or Section)
  --full               Produce detailed output
#{Commands.standard_options_help}
#{Commands.data_model_options_help}

#{Commands.data_model_help}
Note: The --stdout option has no effect in this command.
      
OBJPATH is the object path of a Target, an AddressContainer (e.g.  Map, Section)
object or a Revision. If a Target object, all revisions in all AddressContainer
objects will be listed. If an AddressContainer object, all Revisions in the 
AddressContainer will be listed. 

Examples:
  # List all Revision objects in Map 0x1000 in Process 999
  bgo revision --full process/999/map/0x1000
  # List addresses in Revision 1 of Map 0x500 in Process 1000
  bgo revision -a process/1000/0x500map/revision/1
  # List changed bytes in Revision 2 of Map 0x1000 in Process 999
  bgo revision -b process/999/0x1000map/revision/2

See also: revision-create, revision-edit, revision-delete
"
# ----------------------------------------------------------------------

      def self.invoke_with_state(state, options)

        options.idents.each do |ident|
          obj = state.item_at_obj_path ident
          if obj.respond_to? :address_containers
            list_ac_revisions(obj, options)
            next
          elsif obj.respond_to? :revisions
            list_revisions(obj, options)
            next
          elsif ! obj.kind_of? Bgo::ImageRevision
            $stderr.puts "Invalid object path: #{ident}"
            next
          end

          options.list_revisions ? list_revision(obj, options) : \
                                   show_revision(obj, options)
        end

        true
      end

      def self.get_options(args)
        options = super

        options.idents = []

        options.show_addresses = false
        options.show_changed = false
        options.show_comment = false
        options.show_empty = false
        options.show_ident = false
        options.list_revisions = false
        options.details = false

        opts = OptionParser.new do |opts|
          opts.on( '-a', '--addresses' ) { options.show_addresses = true }
          opts.on( '-b', '--changed-bytes' ) { options.show_changed = true }
          opts.on( '-c', '--comment' ) { options.show_comment = true }
          opts.on( '-e', '--is-empty' ) { options.show_empty = true }
          opts.on( '-i', '--ident' ) { options.show_ident = true }
          opts.on( '-l', '--list' ) { options.list_revisions = true }
          opts.on( '--full' ) { options.show_ident = options.show_comment = true
            options.show_empty = options.details = true }

          Commands.data_model_options(options, opts)
          Commands.standard_options(options, opts)
        end

        opts.parse!(args)

        raise "Insufficient arguments" if args.count < 1
        while args.length > 0
          options.idents << args.shift
        end

        select_show_full(options) if not show_option_selected(options)

        return options
      end

      def self.show_option_selected(options)
        options.show_addresses || options.show_changed || 
        options.show_comment || options.show_empty || options.show_ident
      end

      def self.select_show_full(options)
        options.show_comment = options.show_empty = options.show_ident = true
      end

      def self.show_revision(rev, options)
        show_ident(rev, options) if options.show_ident
        show_empty(rev, options) if options.show_empty
        show_comment(rev, options) if options.show_comment
        show_changed_bytes(rev, options) if options.show_changed
        show_addresses(rev, options) if options.show_addresses
      end

      def self.show_ident(rev, options)
        puts "#{options.details ? 'Object Path: ' : ''}#{rev.obj_path}" 
      end

      def self.show_empty(rev, options)
        str = (rev.patchable?) ? 'no' : 'yes'
        puts "#{options.details ? 'Empty Revision? ' : ''}#{str}"
      end

      def self.show_comment(rev, options)
        txt = rev.comment ? rev.comment.text : ''
        puts "#{options.details ? 'Comment: ' : ''}#{txt}"
      end

      def self.show_changed_bytes(rev, options)
        puts "Changed Bytes:" if options.details
        rev.changed_bytes.sort { |a,b| a[0] <=> b[0] }.each do |k,v|
          puts "%08X : %02X" % k, v
        end
      end

      def self.show_addresses(rev, options)
        puts "Addresses:" if options.details
        rev.addresses.each do |addr|
          puts "%08X : %s" % [addr.vma, addr.inspect]
        end
      end

      def self.list_ac_revisions(tgt, options)
        tgt.address_containers.each do |ac|
          puts "Container #{ac.class.name} #{ac.ident}:" # if options.details
          list_revisions(ac, options, "\t")
        end
      end

      def self.list_revisions(ac, options, indent='')
        ac.revisions.each { |rev| list_revision(rev, options, indent) }
      end

      def self.list_revision(obj, options, indent='')
        if obj.kind_of? Bgo::ImageRevision
          puts indent + (options.details ? obj.inspect : obj.ident.to_s)
        else
          puts "Not a BGO Revision: #{obj.class} #{obj.inspect}"
        end
      end

    end

  end
end

