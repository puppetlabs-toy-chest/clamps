class clamps::agent (
  $nonroot_users = '2',
  $master = $::servername,
  $amqpass = 'password',
) {

  $nonroot_usernames = clamps_users($nonroot_users)

  ::clamps::users { $nonroot_usernames: 
    servername => $master,
  }
  #::clamps::mcollective { $nonroot_usernames: 
  #  amqserver => $master,
  #  amqpass   => $amqpass,
  #}
}
