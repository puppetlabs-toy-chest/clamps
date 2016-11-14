define clamps::users (
  $user           = $title,
  $servername     = $servername,
  $ca_server      = $servername,
  $serverlist     = $serverlist,
  $metrics_server = undef,
  $metrics_port   = 2003,
  $daemonize      = false,
  $run_pxp        = false,
  $splay          = false,
  $splaylimit     = undef,
) {

  $user_cron_minute = clamps_user_number($user) % 30

  $cron_1 = $user_cron_minute
  $cron_2 = $user_cron_minute + 30

  user { $user:
    ensure     => present,
    managehome => true,
  }

  $config_path = "/home/${user}/.puppetlabs"
  $agent_certname = "${user}-${::fqdn}"

  file { [
    $config_path,
    "${config_path}/bin",
    "${config_path}/etc",
    "${config_path}/etc/puppet",
    "${config_path}/etc/pxp-agent",
    "${config_path}/var",
    "${config_path}/var/log",
    "${config_path}/var/run",
    "${config_path}/opt",
    "${config_path}/opt/pxp-agent",
    "${config_path}/opt/pxp-agent/spool",
    "${config_path}/opt/pxp-agent/modules",
    ]:
    ensure => directory,
    owner  => $user,
  }

  Ini_setting {
    ensure  => 'present',
    section => 'agent',
    path    => "${config_path}/etc/puppet/puppet.conf",
  }

  ini_setting { "${user}-certname":
    setting => 'certname',
    value   => $agent_certname,
  }

  ini_setting { "${user}-servername":
    setting => 'server',
    value   => "$servername",
  }

  ini_setting { "${user}-serverlist":
    setting => 'server_list',
    value   => "$serverlist",
  }

  ini_setting { "${user}-ca_server":
    setting => 'ca_server',
    value   => $ca_server,
  }

  file { "${config_path}/etc/pxp-agent/pxp-agent.conf":
    ensure  => file,
    owner   => $user,
    content => template('clamps/pxp-agent.conf.erb'),
    require =>File["${config_path}/etc/pxp-agent/"],
  }

  file { "${config_path}/opt/pxp-agent/modules/pxp-module-puppet":
    ensure  => file,
    owner   => $user,
    mode    => '755',
    content => file('clamps/pxp-module-puppet'),
    require =>File["${config_path}/opt/pxp-agent/modules"],
  }

  if $run_pxp {
    # there must be a safer way to do this
    exec { "user ${user} puppet agent cert":
      command => "/opt/puppetlabs/puppet/bin/puppet agent -t --noop --waitforcert=10 >/dev/null 2>&1",
      user => $user,
      environment => ["HOME=/home/${user}"],
      path => "/bin:/usr/bin",
      creates => "${config_path}/etc/puppet/ssl/certs/${agent_certname}.pem",
    }
    $pxp_ensure="running"
  } else {
    $pxp_ensure="stopped"
  }
  $pxp_service_script = "${config_path}/bin/pxp-agent.init"
  file { "${pxp_service_script}":
    ensure => file,
    owner => $user,
    mode => '755',
    content => template('clamps/pxp-agent.init.erb'),
    require =>File["${config_path}/bin"],
  }->
  service {"$user-pxp-agent":
    ensure => $pxp_ensure,
    start => "${pxp_service_script} start",
    stop => "${pxp_service_script} stop",
    status => "${pxp_service_script} status",
    subscribe => File["${config_path}/etc/pxp-agent/pxp-agent.conf"],
  }

  if $daemonize {

    exec { "user ${user} daemon puppet agent":
      command => "/opt/puppetlabs/puppet/bin/puppet agent --daemonize >/dev/null 2>&1",
      user => $user,
      environment => ["HOME=/home/${user}"],
      path => "/bin:/usr/bin",
      unless => "ps -o pid= -p `cat ${config_path}/var/run/agent.pid`",
    }

  } else {

    if $splaylimit {
      $splaylimitarg = "--splaylimit ${splaylimit}"
    } else {
      $splaylimitarg = ""
    }

    if $splay or $splaylimit {
      $splayarg = "--splay"
    } else {
      $splayarg = ""
    }

    if $metrics_server {
      file { "/home/${user}/time-puppet-run.sh":
        ensure => file,
        content => "TIMEFORMAT=\"metrics.${::fqdn}.${user}.time %R `date +%s`\"; TIME=$( { time /opt/puppetlabs/puppet/bin/puppet agent --onetime --no-daemonize ${splayarg} ${splaylimitarg} > /dev/null; } 2>&1 ); echo \$TIME | nc ${metrics_server} ${metrics_port}",
      }
    }

    $cron_command = $metrics_server ? {
      undef   => "/opt/puppetlabs/puppet/bin/puppet agent --onetime --no-daemonize ${splayarg} ${splaylimitarg}",
      default => "/home/${user}/time-puppet-run.sh",
    }

    cron { "cron.puppet.${user}":
      command => $cron_command,
      user    => $user,
      minute  => [ $cron_1, $cron_2 ],
      require => File["/home/${user}/.puppetlabs"],
    }
  }
}
