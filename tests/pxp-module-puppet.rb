require 'facter'
require 'erb'
require 'fileutils'

@facts = Facter.to_hash
@agent_env = 'production'
@servername = 'foo'
@user = 'user1'
@agent_certname = "#{@user}-#{@facts['fqdn']}"
@config_path = File.join(ENV['HOME'], '.puppetlabs')

FileUtils::mkdir_p("#{@config_path}/opt/pxp-agent/modules")
temp = ERB.new(File.read('templates/pxp-module-puppet.erb'))
File.write("#{@config_path}/opt/pxp-agent/modules/pxp-module-puppet", temp.result)
