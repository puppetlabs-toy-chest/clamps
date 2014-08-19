#!/usr/bin/env ruby

module Puppet::Parser::Functions
  newfunction(:clamps_users, :type => :rvalue) do |arg|
    users = Array.new
    $range = arg[0].to_i
    for i in 1..$range
      users.push("user#{i}")
    end
    return users
  end
end
