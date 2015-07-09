class clamps (
  $logic            = '1',
  $num_static_files = 20,
) {
  # create dynamic files
  include "clamps::logic::c_00${logic}"

  # create static files
  $static_files = clamps_static_files("/home/${id}", $num_static_files)
  file { $static_files:
    ensure  => file,
    content => "This is static file content for file ${name}.",
  }
}
