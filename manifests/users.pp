define clamps::users (
  $user           = $title,
  $servername     = $servername,
  $ca_server      = $servername,
  $metrics_server = undef,
  $metrics_port   = 2003,
  $daemonize      = false,
  $splay          = false,
  $splaylimit     = undef,
) {

  $cron_1 = fqdn_rand('30',$user)
  $cron_2 = fqdn_rand('30',$user) + 30

  user { $user:
    ensure     => present,
    managehome => true,
  }

  file { "/home/${user}/.puppetlabs":
    ensure => directory,
    owner  => $user,
  }

  Ini_setting {
    ensure  => 'present',
    section => 'agent',
    path    => "/home/${user}/.puppetlabs/etc/puppet/puppet.conf",
  }

  ini_setting { "${user}-certname":
    setting => 'certname',
    value   => "${user}-${::fqdn}",
  }

  ini_setting { "${user}-servername":
    setting => 'server',
    value   => "$servername",
  }

  ini_setting { "${user}-ca_server":
    setting => 'ca_server',
    value   => $ca_server,
  }

  if $daemonize {

    exec { "user ${user} daemon puppet agent":
      command => "/opt/puppetlabs/puppet/bin/puppet agent --daemonize >/dev/null 2>&1",
      user => $user,
      environment => ["HOME=/home/${user}"],
      path => "/bin:/usr/bin"
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
