#!/usr/bin/env ruby
# :title: BGO Git
=begin rdoc
=Git Backend for BGO
<i>Copyright 2013 Thoughtgang <http://www.thoughtgang.org></i>
=end

$DEBUG_GIT ||= false    # Set to true to print Bgo::Git debug messages

module Bgo
  module Git
    autoload :AddressContainerClass, 'bgo/application/git/address_container.rb'
    autoload :AddressContainerObject, 'bgo/application/git/address_container.rb'
    autoload :CommitInfo, 'bgo/application/git/repo.rb'
    autoload :Image, 'bgo/application/git/image.rb'
    autoload :ImageChangeset, 'bgo/application/git/image_changeset.rb'
    autoload :ImageRevision, 'bgo/application/git/image_revision.rb'
    autoload :Map, 'bgo/application/git/map.rb'
    autoload :ModelItemClass, 'bgo/application/git/model_item.rb'
    autoload :ModelItemObject, 'bgo/application/git/model_item.rb'
    autoload :Packet, 'bgo/application/git/packet.rb'
    autoload :Process, 'bgo/application/git/process.rb'
    autoload :Project, 'bgo/application/git/project.rb'
    autoload :RemoteImage, 'bgo/application/git/image.rb'
    autoload :Repo, 'bgo/application/git/repo.rb'
    autoload :Section, 'bgo/application/git/section.rb'
    autoload :SectionedTargetObject, 'bgo/application/git/sectioned_target.rb'
    autoload :TargetClass, 'bgo/application/git/target.rb'
    autoload :TargetFile, 'bgo/application/git/file.rb'
    autoload :TargetObject, 'bgo/application/git/target.rb'
    autoload :VirtualImage, 'bgo/application/git/image.rb'
  end
end
