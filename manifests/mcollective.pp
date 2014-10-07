define clamps::mcollective (
  $user = $title,
  $amqpass = 'password',
  $amqserver = '$::server',
) {

  # Directories to create / files to copy
  # plugin.ssl_server_private = /etc/puppetlabs/mcollective/ssl/mcollective-private.pem
  # plugin.ssl_server_public = /etc/puppetlabs/mcollective/ssl/mcollective-public.pem
  # plugin.ssl_client_cert_dir = /etc/puppetlabs/mcollective/ssl/clients/

  File {
    owner  => $user,
    group  => $user,
    mode   => '0600',
    notify => Service["pe-mcollective-$user"],
  }

  file { [
    "/home/$user/.mcollective",
    "/home/$user/.mcollective/log/",
    "/home/$user/.mcollective/ssl/",
    "/home/$user/.mcollective/ssl/clients" ]:
    ensure  => directory,
    require => User["$user"],
  }


  # plugin.activemq.pool.1.ssl.ca = /etc/puppetlabs/mcollective/ssl/mcollective-cacert.pem
  # plugin.activemq.pool.1.ssl.key = /etc/puppetlabs/mcollective/ssl/mcollective-private.pem
  # plugin.activemq.pool.1.ssl.cert = /etc/puppetlabs/mcollective/ssl/mcollective-cert.pem

  file { "/home/$user/.mcollective/ssl/ca.cert.pem":
    ensure  => file,
    source  => 'file:///etc/puppetlabs/mcollective/ssl/ca.cert.pem',
    require => File["/home/$user/.mcollective/ssl/"],
    before  => File["/home/$user/.mcollective/server.cfg"],
  }
  file { "/home/$user/.mcollective/ssl/amq.private_key.pem":
    ensure  => file,
    source  => 'file:///etc/puppetlabs/mcollective/ssl/amq.private_key.pem',
    require => File["/home/$user/.mcollective/ssl/"],
    before  => File["/home/$user/.mcollective/server.cfg"],
  }
  file { "/home/$user/.mcollective/ssl/amq.cert.pem":
    ensure  => file,
    source  => 'file:///etc/puppetlabs/mcollective/ssl/amq.cert.pem',
    require => File["/home/$user/.mcollective/ssl/"],
    before  => File["/home/$user/.mcollective/server.cfg"],
  }
  file { "/home/$user/.mcollective/ssl/clients/pe-internal-console-mcollective-client.public_key.pem":
    ensure  => file,
    source  => 'file:///etc/puppetlabs/mcollective/ssl/clients/pe-internal-console-mcollective-client.public_key.pem',
    require => File["/home/$user/.mcollective/ssl/clients/"],
    before  => File["/home/$user/.mcollective/server.cfg"],
  }

  file { "/home/$user/.mcollective/ssl/clients/pe-internal-peadmin-mcollective-client.public_key.pem":
    ensure  => file,
    source  => 'file:///etc/puppetlabs/mcollective/ssl/clients/pe-internal-peadmin-mcollective-client.public_key.pem',
    require => File["/home/$user/.mcollective/ssl/clients/"],
    before  => File["/home/$user/.mcollective/server.cfg"],
  }
  file { "/home/$user/.mcollective/ssl/pe-internal-mcollective-servers.private_key.pem":
    ensure  => file,
    source  => 'file:///etc/puppetlabs/mcollective/ssl/pe-internal-mcollective-servers.private_key.pem',
    require => File["/home/$user/.mcollective/ssl/"],
    before  => File["/home/$user/.mcollective/server.cfg"],
  }
  file { "/home/$user/.mcollective/ssl/pe-internal-mcollective-servers.public_key.pem":
    ensure  => file,
    source  => 'file:///etc/puppetlabs/mcollective/ssl/pe-internal-mcollective-servers.public_key.pem',
    require => File["/home/$user/.mcollective/ssl/"],
    before  => File["/home/$user/.mcollective/server.cfg"],
  }
  file { "/home/$user/.mcollective/server.cfg":
    ensure   => file,
    content  => template('clamps/clamps_server.cfg.erb'),
  }

  service { "pe-mcollective-$user":
    ensure    => running,
    start     => "su $user -c \'/opt/puppet/sbin/mcollectived --pid /home/$user/.mcollective/pe-mcollective.pid --config=/home/$user/.mcollective/server.cfg &\'",
    status    => "pgrep -u $user mcollectived",
    stop      => "kill -9 `pgrep -u $user mcollectived`",
    subscribe => File["/home/$user/.mcollective/server.cfg"],
  }

}
