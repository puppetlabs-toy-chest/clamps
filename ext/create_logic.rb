(1..100).each do |i|
  f = File.open("c_00#{i}.pp",'w')
  if f
    f.write("class #{ARGV[0]}::c_00#{i} \{\n\n")
    f.write("include #{ARGV[0]}::c_00#{i - 1}\n\n")
    (1..10).each do |j|
      f.write("file \{\"/home/\${id}/#{i}_of_#{j}\": content => fqdn_rand(999999999999999999999999999999),\}\n\n")
    end
    f.write("\}")
  f.close()
  end
end
