class clamps::master {

  file { '/etc/puppetlabs/puppet/autosign.conf':
    ensure  => file,
    owner   => 'pe-puppet',
    group   => 'pe-puppet',
    content => "*",
  }
}
