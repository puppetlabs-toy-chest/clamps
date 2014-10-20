class clamps::agent (
  $nonroot_users = '2',
  $master = $::servername,
  $ca     = $::settings::ca_server,
  $amqpass = 'password',
) {

  user { 'ec2-user':
    ensure           => 'present',
    gid              => '500',
    home             => '/home/ec2-user',
    password         => '!!',
    password_max_age => '99999',
    password_min_age => '0',
    shell            => '/bin/bash',
    uid              => '500',
  }

  $nonroot_usernames = clamps_users($nonroot_users)

  ::clamps::users { $nonroot_usernames: 
    servername => $master,
    ca_server  => $ca,
  }
  #::clamps::mcollective { $nonroot_usernames: 
  #  amqserver => $master,
  #  amqpass   => $amqpass,
  #}

  #resources {'user':
  #  purge              => true,
  #  unless_system_user => true,
  # }

}
