require 'puppet'

class Clamps_Packages

  attr_accessor :last_collection_time

  def initialize
    @last_collection_time = nil
  end

  def gather_inventory
    start_time = Time.now
    resources = Puppet::Resource.indirection.search('package', {})
    packages = []

    resources.each do |resource|
      resource_versions = [resource[:ensure]].flatten # ensure can be an array or string
      resource_versions.each do |version|
        packages << [resource.title.to_s, version, resource[:provider]]
      end
    end

    @last_collection_time = Time.now - start_time
    packages
  end

  def enabled?
    enabled_file = '/tmp/package_inventory_enabled'
    if Facter.value('operatingsystem') == 'windows'
      enabled_file = File.join(Facter.value('common_appdata'),
                               'PuppetLabs/puppet/cache/state/package_inventory_enabled')
    end
    File.exists?(enabled_file)
  end
end

module Clamps_Inventory
  def self.add_inventory(packages)
    Facter.add(:_puppet_inventory_1) do
      confine do
        packages.enabled?
      end

      setcode do
        { 'packages' => packages.gather_inventory }
      end
    end
  end

  def self.add_metadata(packages)
    Facter.add(:puppet_inventory_metadata) do
      setcode do
        # Do this check here to force resolution of the actual inventory
        unless Facter.value('_puppet_inventory_1')
          packages.last_collection_time = 0
        end

        { 'packages' => { 'collection_enabled' => packages.enabled?,
                          'last_collection_time' => "#{packages.last_collection_time.round(4)}s" }}
      end
    end
  end

  def self.add_facts
    packages = Clamps_Packages.new
    Clamps_Inventory.add_inventory(packages)
    Clamps_Inventory.add_metadata(packages)
  end
end

Clamps_Inventory.add_facts
