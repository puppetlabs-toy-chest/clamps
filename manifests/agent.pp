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


  # This will not allow the "main" mcollective to start as
  # it simply checks for a process named mcollective.
  # The status override in the service resource makes the
  # non-root nodes work though
  ::clamps::mcollective { $nonroot_usernames: 
    amqserver => $master,
    amqpass   => $amqpass,
  }

  # Need to manage the ec2-user if you enabled this
  #resources {'user':
  #  purge              => true,
  #  unless_system_user => true,
  # }

}
