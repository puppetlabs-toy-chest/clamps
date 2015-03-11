Clamps works with [beaker](https://github.com/puppetlabs/beaker) and the [Puppet Enterprise acceptance test suite](https://github.com/puppetlabs/pe_acceptance_tests) to build Amazon EC2 nodes on which it will simulate realistic Puppet client-server traffic and facts activity for performance testing.  See the [setup/scale documentation](https://github.com/puppetlabs/pe_acceptance_tests/tree/3.8.x/setup/scale) for more discussion on performance testing.

Clamps generates a random set of users, and a random number of facts (from 5 to 75 facts). The facts change on every run which will also generate activity with puppetdb.  In testing, a m3.xlarge can run about 100 users with responsive mcollective and puppet runs.

### Using Clamps

To run a performance test with clamps, you will need to do the following:

 - Make sure that you have your SSH public key registered in [puppetlabs/puppetlabs-sshkeys](https://github.com/puppetlabs/puppetlabs-sshkeys) so that your key will be made available on the EC2 nodes that will be created.  You may need to file a pull request to make this happen (e.g., [puppetlabs/puppetlabs-sshkeys#81](https://github.com/puppetlabs/puppetlabs-sshkeys/pull/81).  Once this has landed your keys should be available for logging in on the `root` account of the EC2 nodes you will be creating.

 - Make sure that you have an AWS keypair (access key and secret access key) with sufficient permissions to be able to create and manage EC2 nodes.  You can create a help desk request on the [IT Help Desk - AWS Account portal](https://tickets.puppetlabs.com/servicedesk/customer/portal/2/create/132)

 - Create a `~/.fog` file with your AWS credentials:

```
access_key: <your access key here>
secret_access_key: <your secret access key here>
```

 - Check out the PE acceptance tests:

```
$ cd ~/src/  # or wherever you put your git checkouts
$ git clone https://github.com/puppetlabs/pe_acceptance_tests.git
$ cd pe_acceptance_tests
$ bundle install --path vendor/bundle
```

 - Set up your configuration file:

```
$ cd ~/src/  # or wherever you put your git checkouts
$ git clone https://github.com/puppetlabs/clamps.git
$ cd pe_acceptance_tests
$ mkdir -p config
$ cp ../clamps/examples/12-host.cfg config/test.cfg
```

 - Update the configuration file:
   - Replace any occurences of `PUPPET_USER` with your local username.
   - Make sure that `:pe_dir:` points to where your downloaded copy of Puppet Enterprise can be found.
   - Check that the values for `:default_vmname:`, `:default_platform:` and `:default_snapshot:` make sense.
   - Feel free to tune the settings in the `clamps:` section.

 - Download a version of Puppet Enterprise from http://getpe.delivery.puppetlabs.net/ and place it in `~/Downloads/pe/`:

 - Run the "scale" test suite:

```
$ time bundle exec beaker --color --debug --type pe --config config/test.cfg --tests setup/scale --preserve-hosts always
```

If successful, the setup will run for at least 30 minutes. Due to a lack of parallel jobs in Beaker, larger clusters will take even longer.

At the end of the run a dump of host information (suitable for adding to `/etc/hosts`) will be output.

At this point, you should be able to log into the web console (via https) with admin/puppetlabs. E.g., if you have added `test-console` to `/etc/hosts` then you can log in via: https://test-console/

**Note**:  As clamps is still under development, by default the puppet service is turned off on all the hosts (see: https://tickets.puppetlabs.com/browse/QENG-1726). This can be enabled manually by going to “Classification” in the web console. From the web console, open the "PE Mcollective" node group and add the "id is root" rule as shown:

![adding "id is root"](https://cloud.githubusercontent.com/assets/6259/6564511/39eef00e-c677-11e4-8122-64c2e57ccd4f.png)
