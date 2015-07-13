#!/usr/bin/env ruby

module Puppet::Parser::Functions
  newfunction(:clamps_users, :type => :rvalue) do |args|
    range = args.first.to_i

    users = []
    1.upto(range) do |i|
      users << "user#{i}"
    end
    users
  end
end
