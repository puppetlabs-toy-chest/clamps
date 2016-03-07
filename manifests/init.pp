class clamps (
  $num_dynamic_files     = 5,
  $num_static_files      = 20,
  $num_static_files_step = 5,
) {

  file { [
      "/home/${id}/clamps_files/",
      "/home/${id}/clamps_files/static/",
      "/home/${id}/clamps_files/dynamic/",
      "/home/${id}/.facter",
      "/home/${id}/.facter/facts.d"
    ]:
    ensure => directory,
  }

  $static_files_fact_path = "/home/${id}/.facter/facts.d/static_files.txt"

  exec { 'create static_files fact' :
    command => "/bin/echo static_files=50 > ${static_files_fact_path}",
    creates => $static_files_fact_path,
  }

  $num_static_files_to_make_now = min( pick($::static_files, 0) + $num_static_files_step, $num_static_files)

  file { $static_files_fact_path :
    ensure  => present,
    content => "static_files=${num_static_files_to_make_now}",
  }

  # create dynamic files
  $dynamic_files = clamps_files("/home/${id}/clamps_files/dynamic/", $num_dynamic_files)
  each($dynamic_files) | $index, $filename | {
    file { $filename:
      ensure  => file,
      content => "This is dynamic file content for file ${filename}: ${shuffle(fqdn_rand_string(64))}\n",
    }
  }

  # create static files
  $static_files = clamps_files("/home/${id}/clamps_files/static/", $num_static_files_to_make_now + 0 )
  each($static_files) | $index, $filename | {
    file { $filename:
      ensure  => file,
      content => "This is static file content for file ${filename}.\n",
    }
  }
}
