define clamps::users (
  $user = $title,
  $servername = $servername,
) {

  $cron_1 = fqdn_rand('20',$user)
  $cron_2 = fqdn_rand('20',$user) + 20
  $cron_3 = fqdn_rand('20',$user) + 40

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

  cron { "cron.puppet.${user}":
    command => '/opt/puppet/bin/puppet --onetime --no-daemonize',
    user    => "${user}",
    minute  => [ $cron_1, $cron_2, $cron_3 ],
    require => File["/home/${user}/.puppet"],
  }
}
