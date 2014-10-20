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

  ssh_authorized_key {'ec2-user':
    ensure          => present,
    name            => 'dougrosserpuppet',
    user            => 'ec2-user',
    type            => 'ssh-rsa',
    key             => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCI3aX3if3EYx3tAB0Uz2r53nt4PWFV/RBWHNYhRhH4I1WDhDGcLeZv8WDzzKHDXEYJfPDyWXmXzyUGKLYo89qY3TCVD2rRZceXgbJxqQyG5Ee76ek0JExMqKXY0oOBoAPZ5xtEtpvXaZhUGiZs2TuXDAvPaPhARXk2MKbJ4gV7J4MFZG2HZMl53YO+aMD6GcNs88Ai7WuOL2YA6ErK7eSd9Q7H/8FsvmDDSaJ2tpNe9/N1dRI25czcI6n5d9PJ0m8fBjlQ9lsnC0zf1FclEncgfP2Zyus+g6hsL4Hbjx84IAXaEPZJhoI3wO+fY2sza8yv1Et7s4R7dNLLU7kJCJ9D',
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
