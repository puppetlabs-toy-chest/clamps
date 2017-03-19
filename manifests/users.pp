define clamps::users (
  $user           = $title,
  $servername     = $servername,
  $ca_server      = $servername,
  $metrics_server = undef,
  $metrics_port   = 2003,
  $daemonize      = false,
  $run_pxp        = true,
  $use_cached_catalog = $clamps::agent::use_cached_catalog,
  $run_interval   = $clamps::agent::run_interval,
  $splay          = false,
  $splaylimit     = undef,
) {

  if $run_interval == 30 {
    $user_cron_minute = clamps_user_number($user) % 30
    $cron_minute = [$user_cron_minute, $user_cron_minute + 30]
    $cron_hour = '*'
  } elsif $run_interval == 60 {
    $user_cron_minute = clamps_user_number($user) % 60
    $cron_minute = $user_cron_minute
    $cron_hour = '*'
  } elsif $run_interval == 120 {
    $user_cron_minute = clamps_user_number($user) % 120
    if $user_cron_minute < 60 {
      $cron_minute = $user_cron_minute
      $cron_hour = '0-23/2'
    } else {
      $cron_minute = $user_cron_minute % 60
      $cron_hour = '1-24/2'
    }
  } else {
    fail("only run_intervals of 30/60/120 are supported, not ${run_interval}")
  }

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

  ini_setting { "${user}-ca_server":
    setting => 'ca_server',
    value   => $ca_server,
  }

  ini_setting { "${user}-use_cached_catalog":
    setting => 'use_cached_catalog',
    value   => "${use_cached_catalog}",
  }

  file { "${config_path}/etc/pxp-agent/pxp-agent.conf":
    ensure  => file,
    owner   => $user,
    content => template('clamps/pxp-agent.conf.erb'),
    require =>File["${config_path}/etc/pxp-agent/"],
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
    ensure    => $pxp_ensure,
    start     => "${pxp_service_script} start",
    stop      => "${pxp_service_script} stop",
    restart   => "${pxp_service_script} restart",
    status    => "${pxp_service_script} status",
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
      minute  => $cron_minute,
      hour    => $cron_hour,
      require => File["/home/${user}/.puppetlabs"],
    }
  }
}
