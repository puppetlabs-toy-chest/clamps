class clamps (
  $runinterval = '10m',
  $nonroot_users = ['user1','user2','user3','user4']
) {

  if $id == 'root' {
    include pe_mcollective
    #include ntp
    clamps::users { $nonroot_users: }
    clamps::mcollective { $nonroot_users: }
  }

}
