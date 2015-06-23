class clamps::logic::c_004 {

  include clamps::logic::c_003

  file {"/home/${id}/4_of_1": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/4_of_2": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/4_of_3": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/4_of_4": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/4_of_5": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/4_of_6": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/4_of_7": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/4_of_8": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/4_of_9": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/4_of_10": content => "${fqdn_rand(999999999999999999999999999999)}",}
}
