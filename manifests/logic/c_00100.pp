class clamps::logic::c_00100 {

  include clamps::logic::c_0099

  file {"/home/${id}/100_of_1": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/100_of_2": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/100_of_3": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/100_of_4": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/100_of_5": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/100_of_6": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/100_of_7": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/100_of_8": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/100_of_9": content => "${fqdn_rand(999999999999999999999999999999)}",}
  file {"/home/${id}/100_of_10": content => "${fqdn_rand(999999999999999999999999999999)}",}
}
