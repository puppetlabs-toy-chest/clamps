define clamps::users (
  $user = $title,
  $servername = $servername,
  $ca_server  = $servername,
  $metrics_server = undef,
  $metrics_port = 2003,
) {

  $cron_1 = fqdn_rand('30',$user)
  $cron_2 = fqdn_rand('30',$user) + 30

  user { $user:
    ensure     => present,
    managehome => true,
  }

  file { "/home/${user}/.puppet":
    ensure => directory,
    owner  => $user,
  }

  Ini_setting {
    ensure  => 'present',
    section => 'agent',
    path    => "/home/${user}/.puppet/puppet.conf",
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

  if $metrics_server {
    file { "/home/${user}/time-puppet-run.sh":
      ensure => file,
      content => "TIMEFORMAT=\"metrics.${::fqdn}.${user}.time %R `date +%s`\"; TIME=$( { time /opt/puppet/bin/puppet agent --onetime --no-daemonize > /dev/null; } 2>&1 ); echo \$TIME | nc ${metrics_server} ${metrics_port}",
    }
  }

  $cron_command = $metrics_server ? {
    undef   => '/opt/puppet/bin/puppet agent --onetime --no-daemonize',
    default => "/home/${user}/time-puppet-run.sh",
  }

  cron { "cron.puppet.${user}":
    command => $cron_command,
    user    => $user,
    minute  => [ $cron_1, $cron_2 ],
    require => File["/home/${user}/.puppet"],
  }
}
