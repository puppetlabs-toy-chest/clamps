require 'erb'
require 'fileutils'

@module_helper = "#{File.expand_path(File.dirname(__FILE__))}/../files/pxp-module-helper.rb"
@agent_env = 'production'
@servername = 'foo'
@user = 'user1'
@agent_certname = "#{@user}-foo"
@config_path = File.join(ENV['HOME'], '.puppetlabs')
@facts_cache = '/tmp/facts_cache'
@pxp_mock_puppet = true

FileUtils::mkdir_p("#{@config_path}/opt/pxp-agent/modules")
temp = ERB.new(File.read('templates/pxp-module-puppet.erb'), nil, '-')
File.write("#{@config_path}/opt/pxp-agent/modules/pxp-module-puppet", temp.result)
