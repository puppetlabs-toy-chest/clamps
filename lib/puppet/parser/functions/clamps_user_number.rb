#!/usr/bin/env ruby

#usernames are expected to be =~ /^user\d+$/
#this function is only intended to be used with the clamps_users function
module Puppet::Parser::Functions
  newfunction(:clamps_user_number, :type => :rvalue) do |args|
    username = args.first.to_s

    number = username.sub('user', '')
  end
end
