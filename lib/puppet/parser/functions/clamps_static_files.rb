#!/usr/bin/env ruby

module Puppet::Parser::Functions
  newfunction(:clamps_static_files, :type => :rvalue) do |args|
    base_path = args.first
    count = args.last.to_i

    static_file_names = []
    1.upto(count) do |i|
      static_file_names << File.join(base_path, "static_file_#{i}_of_#{count}")
    end
    static_file_names
  end
end
