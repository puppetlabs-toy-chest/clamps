class clamps::logic::c_002 {

include clamps::logic::c_001

file {"/${::homedir}/2_of_1": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/2_of_2": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/2_of_3": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/2_of_4": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/2_of_5": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/2_of_6": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/2_of_7": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/2_of_8": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/2_of_9": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/2_of_10": content => fqdn_rand(999999999999999999999999999999),}

}