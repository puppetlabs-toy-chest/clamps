class clamps::agent (
  $nonroot_users = '2',
  $master = $::servername,
  $amqserver = $::servername,
  $ca     = $::settings::ca_server,
  $amqpass = file('/etc/puppetlabs/mcollective/credentials'),
  $metrics_server = undef,
  $metrics_port = 2003,
) {

  $nonroot_usernames = clamps_users($nonroot_users)

  ::clamps::users { $nonroot_usernames: 
    servername     => $master,
    ca_server      => $ca,
    metrics_server => $metrics_server,
    metrics_port   => $metrics_port,
  }


  # This will not allow the "main" mcollective to start as
  # it simply checks for a process named mcollective.
  # The status override in the service resource makes the
  # non-root nodes work though
  ::clamps::mcollective { $nonroot_usernames: 
    amqserver => $amqserver,
    amqpass   => $amqpass,
  }

  # Need to manage the ec2-user if you enabled this
  #resources {'user':
  #  purge              => true,
  #  unless_system_user => true,
  # }

}
