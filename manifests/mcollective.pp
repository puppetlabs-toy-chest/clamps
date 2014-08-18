define clamps::mcollective (
  $user = $title,
) {

  # Directories to create / files to copy
  # plugin.ssl_server_private = /etc/puppetlabs/mcollective/ssl/mcollective-private.pem
  # plugin.ssl_server_public = /etc/puppetlabs/mcollective/ssl/mcollective-public.pem
  # plugin.ssl_client_cert_dir = /etc/puppetlabs/mcollective/ssl/clients/

  File {
    owner => $user,
    group => $user,
    mode  => '0600',
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

  file { "/home/$user/.mcollective/ssl/mcollective-cacert.pem":
    ensure  => file,
    source  => 'file:///etc/puppetlabs/mcollective/ssl/mcollective-cacert.pem',
    require => File["/home/$user/.mcollective/ssl/"],
    before  => File["/home/$user/.mcollective/server.cfg"],
  }
  file { "/home/$user/.mcollective/ssl/mcollective-private.pem":
    ensure  => file,
    source  => 'file:///etc/puppetlabs/mcollective/ssl/mcollective-private.pem',
    require => File["/home/$user/.mcollective/ssl/"],
    before  => File["/home/$user/.mcollective/server.cfg"],
  }
  file { "/home/$user/.mcollective/ssl/mcollective-cert.pem":
    ensure  => file,
    source  => 'file:///etc/puppetlabs/mcollective/ssl/mcollective-cert.pem',
    require => File["/home/$user/.mcollective/ssl/"],
    before  => File["/home/$user/.mcollective/server.cfg"],
  }

  file { "/home/$user/.mcollective/server.cfg":
    ensure   => file,
    contents => template('clamps/server.cfg.erb'),
  }

  file { "/etc/init.d/pe-mcollecitve-$user":
    ensure   => file,
    owner    => root,
    group    => root,
    mode     => '0644'
    contents => template('clamps/pe-mcollective.erb'),
  }

  service { "pe-mcollective-$user":
    ensure    => running,
    enable    => true,
    subscribe => [
      File["/home/$user/.mcollective/server.cfg"],
      File["/etc/init.d/pe-mcollective-$user"]
    ],
  }

}
