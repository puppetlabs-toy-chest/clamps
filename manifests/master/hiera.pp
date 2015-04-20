class clamps::master::hiera (
  $generate_data_bindings = true,
) {

  File {
    owner    => $::settings::user,
    group    => $::settings::group, 
  }

  # This is using http://forge.puppetlabs.com/hunner/hiera
  class { '::hiera':
    backends     => [
      'yaml',
    ],
    datadir      => "${::settings::confdir}/hieradata", 
    hierarchy    => [
      'servers/%{::clientcert}',
      '%{environment}',
      'global',
    ],
    datadir_manage => false,
  }

  # Normally this directory would live in the control repo
  # We programmatically generate this data so it should not be
  # Version controlled.

  file { "${::settings::confdir}/hieradata":
    ensure  => directory,
  }


  # The function below generates hiera data keys from the
  # existing classes and their params on disk

  if $generate_data_bindings {

    # Function returns a hash of databindings compatible key names.
    $defaults = clamps_hiera_defaults()

    file { "${::settings::confdir}/hieradata/global.yaml":
      ensure  => file,
      content => inline_template("<%= @defaults.to_yaml %>"),
    }
  }
}
