#!/usr/bin/env ruby

module Puppet::Parser::Functions
  newfunction(:clamps_files, :type => :rvalue) do |args|
    base_path = args.first
    count = args.last.to_i

    file_names = []
    1.upto(count) do |i|
      file_names << File.join(base_path, "file_#{i}_of_#{count}")
    end
    file_names
  end
end
