# generate a random hash with a lot of crap in it, turn it into facts

require 'securerandom'
require 'facter'

$num_of_facts = rand(5..50)

hash_of_facts = Hash.new {|h,k| h[k] = [] }

for i in 1..$num_of_facts
  hash_of_facts[SecureRandom.hex] << SecureRandom.hex
end

hash_of_facts.each_pair do |factname, factvalue|
  Facter.add("clamps_#{factname}") do
    setcode do
      factvalue[0]
    end
  end
end
