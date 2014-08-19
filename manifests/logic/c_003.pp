class clamps::logic::c_003 {

include clamps::logic::c_002

file {"/${::homedir}/3_of_1": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/3_of_2": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/3_of_3": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/3_of_4": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/3_of_5": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/3_of_6": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/3_of_7": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/3_of_8": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/3_of_9": content => fqdn_rand(999999999999999999999999999999),}

file {"/${::homedir}/3_of_10": content => fqdn_rand(999999999999999999999999999999),}

}