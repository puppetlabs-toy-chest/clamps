# To compensate for our "fake" agents having virtually no facts,
# generate some random facts. To better stress test puppetdb, (avoid its data
# deduplication) these facts should:
#
# contain different data each run
# have the same fact name so we don't end up with 4 million facts in puppetdb
# have verying length, to simulate things like SSH keys.

require 'securerandom'
require 'facter'

num_facts = File.exist?('/etc/puppetlabs/num_facts') ? File.read('/etc/puppetlabs/num_facts') : 500
hash_of_facts = Hash.new {|h,k| h[k] = [] }

for i in 1..num_facts
  fact_value = ""
  rand(1..50).times { fact_value << SecureRandom.hex }
  hash_of_facts["fact_#{i}"] << fact_value
end

hash_of_facts.each_pair do |factname, factvalue|
  Facter.add("clamps_#{factname}") do
    setcode do
      factvalue[0]
    end
  end
end
