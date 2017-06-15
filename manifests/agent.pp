class clamps::agent (
  $amqpass               = file('/etc/puppetlabs/mcollective/credentials'),
  $amqserver             = [$::servername],
  $ca                    = $::settings::ca_server,
  $daemonize             = false,
  $environment           = 'production',
  $master                = $::servername,
  $orch_server           = $::servername,
  $metrics_port          = 2003,
  $metrics_server        = undef,
  $nonroot_users         = '2',
  $num_facts_per_agent   = 500,
  $percent_changed_facts = 15,
  $use_cached_catalog    = false,
  $run_interval          = 30,
  $splay                 = false,
  $splaylimit            = undef,
  $mco_daemon            = undef,
  $pxp_ping_interval     = undef,
  $pxp_mock_puppet       = false,
  $pxp_log_level         = 'debug',
  $crond                 = 'running',
) {

  # Disable filebucket backups while managing clamps agents.
  # This has no effect on the agent runs themselves.
  File {
    backup => false
  }

  file { '/etc/puppetlabs/clamps':
    ensure => directory
  }

  file { '/etc/puppetlabs/clamps/num_facts':
    ensure  => file,
    content => "${num_facts_per_agent}",
  }

  file { '/etc/puppetlabs/clamps/percent_facts':
    ensure  => file,
    content => "${percent_changed_facts}",
  }

  # Write facts to a cache for clamps agents to use.
  $facts_cache = '/etc/puppetlabs/clamps/facts_cache'
  $module_helper = '/etc/puppetlabs/clamps/pxp-module-helper.rb'
  if $pxp_mock_puppet {
    file { $facts_cache:
      ensure  => file,
      content => inline_template("<%= require 'json'; @facts.to_json %>"),
    }

    file { $module_helper:
      ensure => file,
      source => 'puppet:///modules/clamps/pxp-module-helper.rb',
    }
  }

  # Ensure crond is in the expected state, as we rely
  # on it for agent runs.
  service { 'crond':
    ensure  => $crond,
  }

  $nonroot_usernames = clamps_users($nonroot_users)

  ::clamps::users { $nonroot_usernames:
    servername     => $master,
    ca_server      => $ca,
    metrics_server => $metrics_server,
    metrics_port   => $metrics_port,
    daemonize      => $daemonize,
    splay          => $splay,
    splaylimit     => $splaylimit,
    facts_cache    => $facts_cache,
    module_helper  => $module_helper,
  }

  package {'psmisc':
    ensure => present,
  }

  $pxp_agent_cron = @("EOT")
    /home/*/.puppetlabs/var/log/pxp-agent.log {
      daily
      missingok
      rotate 30
      compress
      notifempty
      sharedscripts
      postrotate
        /usr/bin/killall -USR2 pxp-agent
      endscript
    }
  | EOT

  file { "/etc/puppetlabs/clamps/logrotate.conf":
    ensure  => file,
    content => $pxp_agent_cron,
  }

  cron { "cron.pxp-agent.${user}":
    command => 'logrotate /etc/puppetlabs/clamps/logrotate.conf',
    hour    => '0',
    require => File['/etc/puppetlabs/clamps/logrotate.conf'],
  }

  if $mco_daemon {
    # This will not allow the "main" mcollective to start as
    # it simply checks for a process named mcollective.
    # The status override in the service resource makes the
    # non-root nodes work though
    ::clamps::mcollective { $nonroot_usernames:
      amqservers => $amqserver,
      amqpass    => $amqpass,
    }
  }

  # Need to manage the ec2-user if you enabled this
  #resources {'user':
  #  purge              => true,
  #  unless_system_user => true,
  # }

}
