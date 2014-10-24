This is a combination of shit\_logic and non root puppet agents.

Replace classification of nodes with pe\_mcollective for it to work, right now it only works with a single master / activemq broker due to janky server.cfg creation for mcollective.

This is now three classes that you have to use the PE 3.4 Node Manager to classify the servers with (since this also lets us test the NC now).

the 'clamps' itself is just assigned to the nonroot puppet nodes (use a rule to assign to $id != root).

Modify the pe\_mcollective rule in the console to require $id = root.

Assign 'clamps::master' to the master node in the cluster.

Assign 'clamps::agent' to the root agents on your nodes, as it will install the non root puppet agent accounts, setup their cron job and configuration (create a node group of 'fqdn != list of masters / console /puppetdb' and excludes $id != root)

This also uses the lots\_of\_facts fact, which generates a random amount of facts between 5 and 75 to compensate for the lack of facts gathered because non root doesn't appear to be able to retrieve as many facts. They change every puppet run also - so its hitting puppetdb more also.

In testing, a m3.xlarge can run about 100 users with responsive mcollective and puppet runs.
