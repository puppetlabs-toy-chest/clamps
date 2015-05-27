# To compensate for our non-root user agents having virtually no facts, and to
# exercise the parts of the stack which need to handle changing fact data (e.g.,
# puppetdb), we generate facts and provide changing fact values over the course
# of multiple runs here.
#
# We allow the CLAMPS configuration to dictate how many facts are generated, and
# what percentage of facts should change over each run.
#
# In earlier implementations, fact randomization generated long random values
# for every fact, with every value changing on every run. This meant 100% fact
# churn, which ends up trashing the puppetdb cache (which ends up doing bad
# things to puppetdb).
#
# Since the goal of CLAMPS is to provide load sufficient to exercise a puppet
# deployment, and to give confidence that if the running system falls over that
# it was not due to the artificial nature of testing, this prior approach was
# undesirable.
#
# Here there are a few things happening:
#
# We extracted a set of real-world fact names from an agent running on an EC2
# node. We saved the lengths of the fact values. This allows us to generate
# facts and values with at least the length distributions we could expect to see
# in the real world.
#
# We generate a list of CLAMPS fact names that will be persistent across runs.
# For a given number of facts per agent (`#number_of_facts`, below), the same
# list of fact names will always be generated. These will be in the form
# clamps_factname_index (e.g., "clamps_uptime_3"). This also implies a
# consistency across agents running independently -- i.e., if two agents are
# requested to have 100 facts, they will be the same 100 named facts on each
# agent.
#
# Based upon configuration (`#percent_to_change` below), we choose a certain
# number of facts to receive random values each run. The names of the facts
# which get random values will be consistent between runs, and all other facts
# always have the same values. This will also actually be consistent between
# agents as well, provided the `#number_of_facts` and `#percent_to_change`
# values are set identically.
#
# By choosing a fixed set of random fact names to change we avoid variation in
# churn. The alternative is that if a random, say, 10% of facts are given random
# values, we are either forced to save old fact values between runs to avoid
# changing them (which introduces unwanted storage and serialization headaches),
# or we end up changing old "randomized" values back to some known fixed value
# while we randomize other fact values (which results in an inconsistent amount
# of change between runs).
#
# Our techniques here should also better simulate real-world behavior, where
# many facts never change over the lifetime of a node, and certain specific
# facts are known to change regularly, across most nodes.

require "facter"

# Number of facts to be generated, via the CLAMPS configuration (default: 500).
def number_of_facts
  @number_of_facts ||=
    File.exist?("/etc/puppetlabs/clamps/num_facts") ?
      File.read("/etc/puppetlabs/clamps/num_facts").to_i : 500
end

# Percentage of facts that should have changing values on each run, via the
# CLAMPS configuration (default: 15).
def percent_to_change
  @percent_to_change ||=
    File.exist?("/etc/puppetlabs/clamps/percent_facts") ?
      File.read("/etc/puppetlabs/clamps/percent_facts").to_i : 15
end

# Returns a Hash with `#number_of_facts` entries: keys are fact names, of the
# form "clamps_#{name}_#{index}" (e.g., "clamps_uptime_1") taken from
# `#sample_facts_with_lengths`. Values are the lengths of a fact value for this
# key.
def actual_facts_with_lengths
  available = sample_facts_with_lengths.keys.sort
  results = {}

  pass = 1
  0.upto(number_of_facts - 1) do |current|
    fact_name = available[current % available.size]
    results["clamps_#{fact_name}_#{pass}"] = sample_facts_with_lengths[fact_name]
    pass += 1 if (current + 1) % available.size == 0
  end

  results
end

# Returns a random (alphanumeric + space) string of length `length`
def random_string(length)
  charset = (('0'..'9').to_a + ('a'..'z').to_a + ('A' .. 'Z').to_a + [" "])
  (0...length).map{ charset[rand(charset.size)] }.join
end

# Returns a fixed-content string of length `length`
def fill_string(length)
  "A" * length
end

# Should debugging output be displayed?
def debugging?
  !!ENV['DEBUG']
end

# Update Facter with the given fact name and value.
def set_fact_value(name, value)
  puts "setting fact [#{name}] to [#{value}]" if debugging?
  Facter.add(name) do
    setcode do
      value
    end
  end
end

# Fisher-Yates shuffle a copy of the list `list`
# (http://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle)
def permute(list)
  working = list.dup

  0.upto(working.length - 2) do |index|
    position = rand(working.length - index) + index
    working[position], working[index] = working[index], working[position]
  end

  working
end

# Returns a stable randomized sublist of length `length` from the list `list`.
#
# We use the Fisher-Yates `#permute` method to generate a shuffled `list`,
# and select `length` elements from the front. We guarantee to provide the same
# sublist for a given `list` + `length` combo, whenever it is called (even
# across different process invocations), hence "stable".
def stable_random_sublist(list, length)
  srand(1234567890)   # seed is arbitrary, but fixed srand() makes rand() stable
  sub_list = permute(list).take(length)
  srand               # revert back to unstable for any later calls to rand()
  sub_list
end

# Returns an Array of fact names which should receive randomized values. We use
# `#stable_random_sublist` to ensure that this list is always the same, even
# on invocations in different processes.
def fact_names_to_randomize
  total_facts = actual_facts_with_lengths.keys.size
  number_of_facts = (total_facts * (percent_to_change / 100.0)).to_i
  stable_random_sublist(actual_facts_with_lengths.keys.sort, number_of_facts)
end

# Returns a Hash containing a list of real-world fact names as keys, with a
# sampled real-world string length for the fact's value.  Allows generating
# unchanging or randomized fact values with real-world length distributions.
def sample_facts_with_lengths
  {
    "architecture" => 7,
    "augeasversion" => 6,
    "bios_release_date" => 11,
    "bios_vendor" => 4,
    "bios_version" => 11,
    "blockdevice_xvda_size" => 11,
    "blockdevices" => 5,
    "domain" => 27,
    "ec2_ami_id" => 13,
    "ec2_ami_launch_index" => 2,
    "ec2_ami_manifest_path" => 10,
    "ec2_block_device_mapping_ami" => 10,
    "ec2_block_device_mapping_root" => 10,
    "ec2_hostname" => 43,
    "ec2_instance_action" => 5,
    "ec2_instance_id" => 11,
    "ec2_instance_type" => 10,
    "ec2_local_hostname" => 43,
    "ec2_local_ipv4" => 13,
    "ec2_mac" => 18,
    "ec2_metadata" => 1931,
    "ec2_metrics_vhostmd" => 39,
    "ec2_network_interfaces_macs_12:34:56:78:90:ab_device_number" => 2,
    "ec2_network_interfaces_macs_12:34:56:78:90:ab_interface_id" => 13,
    "ec2_network_interfaces_macs_12:34:56:78:90:ab_ipv4_associations_127.0.0.1" => 13,
    "ec2_network_interfaces_macs_12:34:56:78:90:ab_local_hostname" => 43,
    "ec2_network_interfaces_macs_12:34:56:78:90:ab_local_ipv4s" => 13,
    "ec2_network_interfaces_macs_12:34:56:78:90:ab_mac" => 18,
    "ec2_network_interfaces_macs_12:34:56:78:90:ab_owner_id" => 13,
    "ec2_network_interfaces_macs_12:34:56:78:90:ab_public_hostname" => 49,
    "ec2_network_interfaces_macs_12:34:56:78:90:ab_public_ipv4s" => 13,
    "ec2_network_interfaces_macs_12:34:56:78:90:ab_security_group_ids" => 12,
    "ec2_network_interfaces_macs_12:34:56:78:90:ab_security_groups" => 18,
    "ec2_network_interfaces_macs_12:34:56:78:90:ab_subnet_id" => 16,
    "ec2_network_interfaces_macs_12:34:56:78:90:ab_subnet_ipv4_cidr_block" => 15,
    "ec2_network_interfaces_macs_12:34:56:78:90:ab_vpc_id" => 13,
    "ec2_network_interfaces_macs_12:34:56:78:90:ab_vpc_ipv4_cidr_block" => 14,
    "ec2_placement_availability_zone" => 11,
    "ec2_product_codes" => 26,
    "ec2_profile" => 12,
    "ec2_public_hostname" => 49,
    "ec2_public_ipv4" => 13,
    "ec2_public_keys_0_openssh_key" => 419,
    "ec2_reservation_id" => 11,
    "ec2_security_groups" => 18,
    "ec2_services_domain" => 14,
    "facterversion" => 6,
    "filesystems" => 12,
    "fqdn" => 34,
    "gid" => 5,
    "hardwareisa" => 7,
    "hardwaremodel" => 7,
    "hostname" => 7,
    "id" => 5,
    "interfaces" => 8,
    "ipaddress" => 13,
    "ipaddress_eth0" => 13,
    "ipaddress_lo" => 10,
    "is_virtual" => 5,
    "kernel" => 6,
    "kernelmajversion" => 5,
    "kernelrelease" => 26,
    "kernelversion" => 7,
    "macaddress" => 18,
    "macaddress_eth0" => 18,
    "manufacturer" => 4,
    "memoryfree" => 8,
    "memoryfree_mb" => 8,
    "memorysize" => 9,
    "memorysize_mb" => 9,
    "mtu_eth0" => 5,
    "mtu_lo" => 6,
    "netmask" => 14,
    "netmask_eth0" => 14,
    "netmask_lo" => 10,
    "network_eth0" => 12,
    "network_lo" => 10,
    "operatingsystem" => 7,
    "operatingsystemmajrelease" => 2,
    "operatingsystemrelease" => 9,
    "os" => 100,
    "osfamily" => 7,
    "partitions" => 115,
    "path" => 82,
    "physicalprocessorcount" => 2,
    "processor0" => 42,
    "processor1" => 42,
    "processor2" => 42,
    "processor3" => 42,
    "processorcount" => 2,
    "processors" => 225,
    "productname" => 9,
    "ps" => 7,
    "puppetversion" => 32,
    "rubyplatform" => 13,
    "rubysitedir" => 37,
    "rubyversion" => 6,
    "selinux" => 5,
    "selinux_config_mode" => 10,
    "selinux_config_policy" => 8,
    "selinux_current_mode" => 10,
    "selinux_enforced" => 5,
    "selinux_policyversion" => 3,
    "serialnumber" => 37,
    "sshecdsakey" => 141,
    "sshfp_ecdsa" => 126,
    "sshfp_rsa" => 126,
    "sshrsakey" => 373,
    "swapfree" => 8,
    "swapfree_mb" => 5,
    "swapsize" => 8,
    "swapsize_mb" => 5,
    "system_uptime" => 65,
    "timezone" => 4,
    "type" => 6,
    "uniqueid" => 9,
    "uptime" => 7,
    "uptime_days" => 2,
    "uptime_hours" => 4,
    "uptime_seconds" => 7,
    "uuid" => 37,
    "virtual" => 7,
  }
end

# get the list of facts which should be given random values, make a Hash for
# easily checking whether a name represents a randomized fact.
randomized_facts = fact_names_to_randomize.inject({}) {|hash, name| hash[name] = true; hash }

# for all facts for this agent, assign them values
actual_facts_with_lengths.each_pair do |name, length|
  if randomized_facts[name]
    set_fact_value name, random_string(length)
  else
    set_fact_value name, fill_string(length)
  end
end
