class clamps (
  $runinterval = '10m',
  $nonroot_users = '2',
  $master = $::server,
  $amqpass = 'password',
  $logic = '1',
) {

  $nonroot_usernames = clamps_users($nonroot_users)
  
  include "clamps::logic::c_00${logic}"

  if $id == 'root' {
    include pe_mcollective
    #include ntp
    clamps::users { $nonroot_usernames: 
      servername => $master,
    }
    clamps::mcollective { $nonroot_usernames: 
      amqserver => $master,
      amqpass   => $amqpass,
    }
  }

}
