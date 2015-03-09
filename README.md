Clamps works with [beaker](https://github.com/puppetlabs/beaker) and the [Puppet Enterprise acceptance test suite](https://github.com/puppetlabs/pe_acceptance_tests) to build Amazon EC2 nodes on which it will simulate realistic Puppet client-server traffic and facts activity for performance testing.  See the [setup/scale documentation](https://github.com/puppetlabs/pe_acceptance_tests/tree/3.8.x/setup/scale) for more discussion on performance testing.

### Using Clamps

To run a performance test with clamps, you will need to do the following:

 - Make sure that you have your SSH public key registered in [puppetlabs-modules](https://github.com/puppetlabs/puppetlabs-modules/) so that your key will be made available on the EC2 nodes that will be created.  You may need to file a pull request to make this happen (e.g., [puppetlabs-modules#3605](https://github.com/puppetlabs/puppetlabs-modules/pull/3605)).  Once this has landed your keys should be available after the next 30-minute Puppet run.

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

 - Set up the configuration file:

```
$ mkdir -p config
$ curl https://gist.githubusercontent.com/rick/c527edba111bc9a776b6/raw/12eac7155b312f64623b972cd4b110045b900ca0/test.cfg | sed "s:PUPPET_USER:${USER}" > config/test.cfg
```

 - Download a version of Puppet Enterprise from http://getpe.delivery.puppetlabs.net/ and place it in `~/Downloads/pe/`:

 - Run the "scale" test suite:

```
$ time bundle exec beaker --color --debug --type pe --config config/test.cfg --tests setup/scale --preserve-hosts always
```

#### Discussion

Clamps generates a random set of users, and a random number of facts (from 5 to 75 facts). The facts change on every run which will also generate activity with puppetdb.

In testing, a m3.xlarge can run about 100 users with responsive mcollective and puppet runs.
