class clamps::agent (
  $amqpass             = file('/etc/puppetlabs/mcollective/credentials'),
  $amqserver           = [$::servername],
  $ca                  = $::settings::ca_server,
  $master              = $::servername,
  $metrics_port        = 2003,
  $metrics_server      = undef,
  $nonroot_users       = '2',
  $num_facts_per_agent = 500,
  $shuffle_amq_servers = true,
) {


  file { '/etc/puppetlabs/clamps/num_facts':
    ensure  => file,
    content => $num_facts_per_agent,
  }

  $nonroot_usernames = clamps_users($nonroot_users)

  ::clamps::users { $nonroot_usernames:
    servername     => $master,
    ca_server      => $ca,
    metrics_server => $metrics_server,
    metrics_port   => $metrics_port,
  }

  $amq_servers = $shuffle_amq_servers ? {
    true    => shuffle($amqserver),
    default => $amqserver,
  }

  # This will not allow the "main" mcollective to start as
  # it simply checks for a process named mcollective.
  # The status override in the service resource makes the
  # non-root nodes work though
  ::clamps::mcollective { $nonroot_usernames:
    amqservers => $amq_servers,
    amqpass    => $amqpass,
  }

  # Need to manage the ec2-user if you enabled this
  #resources {'user':
  #  purge              => true,
  #  unless_system_user => true,
  # }

}
