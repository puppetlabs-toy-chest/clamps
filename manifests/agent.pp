class clamps::agent (
  $nonroot_users = '2',
  $master = $::servername,
  $ca     = $::settings::ca_server,
  $amqpass = 'password',
) {

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
