This is a combination of shit\_logic and non root puppet agents.

Replace classification of nodes with pe\_mcollective for it to work, right now it only works with a single master / activemq broker due to janky server.cfg creation for mcollective.

On the 'host' nodes you want the non root agents to run on, either pass the following as hiera data or explicitly call it:

`class { clamps:
  nonroot_users => '50',
  master => FQDN_of_master/amqbroker,
  amqpass => pass_from_existing_server.cfg,
}`

for the non root accounts:

`class { clamps:
  logic => number of logic classes to load,
}`

The clamps module itself uses the $id fact to know if it should create users ($id=root) or not. It only applies the logic module to the nonroot users, since creating nonroot users already creates around 10-20 resources per user.

In testing, a m3.xlarge can run about 100 users with responsive mcollective and puppet runs.
