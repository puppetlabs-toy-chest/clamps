#!/usr/bin/env ruby

# Generate the "logic" file resource puppet manifests, in `manifests/logic`.
# The default class name is `clamps::logic` but can be overridden on the
# command line.  The destination path can also be overridden on the command
# line.

classname  = ARGV.shift || "clamps::logic"
destination = ARGV.shift || File.expand_path(File.join(File.dirname(__FILE__), "..", "manifests", "logic"))

1.upto(100) do |i|
  filename = File.join(destination, "c_00#{i}.pp")
  File.open(filename,'w') do |f|
    puts "Generating file [#{filename}]..."
    f.puts "class #{classname}::c_00#{i} {\n\n"
    f.puts "  include #{classname}::c_00#{i-1}\n\n"
    1.upto(10) do |j|
      f.puts %Q|  file {"/home/${id}/#{i}_of_#{j}\": content => "${fqdn_rand(999999999999999999999999999999)}",}|
    end
    f.puts "}"
  end
end
