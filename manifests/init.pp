class clamps (
  $logic            = '1',
  $num_dynamic_files = 5,
  $num_static_files = 20,
) {

  file { [
      "/home/${id}/clamps_files/",
      "/home/${id}/clamps_files/static/",
      "/home/${id}/clamps_files/dynamic/",
    ]:
    ensure => directory,
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
  $static_files = clamps_files("/home/${id}/clamps_files/static/", $num_static_files)
  each($static_files) | $index, $filename | {
    file { $filename:
      ensure  => file,
      content => "This is static file content for file ${filename}.\n",
    }
  }
}
