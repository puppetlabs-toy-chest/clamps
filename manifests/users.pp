define clamps::users (
  $user = $title,
  $servername = $servername,
  $ca_server  = $servername,
) {

  $cron_1 = fqdn_rand('30',$user)
  $cron_2 = fqdn_rand('30',$user) + 30

  user { $user:
    ensure     => present,
    managehome => 'true',
  }

  file { "/home/${user}/.puppet":
    ensure => directory,
    owner  => $user,
  }

  ini_setting { "${user}-certname":
    ensure  => 'present',
    path    => "/home/${user}/.puppet/puppet.conf",
    section => "agent",
    setting => "certname",
    value   => "${user}-${::fqdn}",
  }
  ini_setting { "${user}-servername":
    ensure  => 'present',
    path    => "/home/${user}/.puppet/puppet.conf",
    section => "agent",
    setting => "server",
    value   => "$servername",
  }

  ini_setting { "${user}-ca_server":
    ensure  => 'present',
    path    => "/home/${user}/.puppet/puppet.conf",
    section => 'agent',
    setting => 'ca_server',
    value   => $ca_server,
  }

  cron { "cron.puppet.${user}":
    command => '/opt/puppet/bin/puppet agent --onetime --no-daemonize',
    user    => "${user}",
    minute  => [ $cron_1, $cron_2 ],
    require => File["/home/${user}/.puppet"],
  }
}
