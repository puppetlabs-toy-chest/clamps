Clamps is a puppet module designed to help simulate realistic facts and resources during scale testing. We anticipate it being used with  [beaker](https://github.com/puppetlabs/beaker), as we do at Puppet Labs, where we set up clusters of nodes using Amazon EC2.

The technique is to generate a random set of users on a machine each running a non-root agent out of the user's home directory. It also generates a random number of facts (from 5 to 75 facts). Since these facts change on each puppet run, this additionally creates puppetdb activity.

In our testing, an Amazon EC2 `m3.xlarge` node can run about 100 users with responsive mcollective and puppet runs.

## Clamps classes


#### `clamps:master`

Assign `clamps::master` to the master node in the cluster.

#### `clamps::agent`

Assign `clamps::agent` to the root agents on your nodes, as it will install the non root puppet agent accounts, setup their cron job and configuration.

This class accepts the following parameters:

 - `$amqpass` (`String`): Credentials for MCollective AMQP bus.
 - `$amqserver` (`String`): Server name for MCollective AMQP connection.
 - `$ca` (`String`): Name of CA server.
 - `$daemonize` (`Boolean`): Run non-root agents daemonized? (default: `false`)
 - `$master` (`String`): Name of puppet master server.
 - `$metrics_port` (`Integer`): Port to use when connecting to graphite server.
 - `$metrics_server` (`String`): Name of server where graphite is running.
 - `$nonroot_users` (`Integer`): Number of non-root user agents to create. (default: 2)
 - `$num_facts_per_agent` (`Integer`): Number of facts to create per non-root user agent.
 - `$shuffle_amq_servers` (`Boolean`): Randomize AMQP servers? (default: `true`)
 - `$splay` (`Boolean`):  Enable `--splay` for non-user agent runs? (default: `false`).  See [Configuration: splay](https://docs.puppetlabs.com/references/latest/configuration.html#splay) for puppet agent semantics.
 - `$splaylimit` (`String`): Set the `--splaylimit` parameter for non-user agent runs? (default: unset). Implies `splay`.  See [Configuration: splaylimit](https://docs.puppetlabs.com/references/latest/configuration.html#splaylimit) for puppet agent semantics.

#### `clamps`

Assign `clamps` to the non-root agents on your nodes.

This class accepts the following parameter:

 - `$logic` (`Integer`): relative level of complexity (hence load) to be introduced to the system. Higher values mean more complexity.

## Clamps Classification

We make use of clamps by assigning the nodes we're scale testing into clamps-related node groups via the Puppet Enterprise web console (see the "Classification" tab there).

The node groups of interest:

#### `Clamps CA`

 - `Clamps CA`: which node will act as the CA for clamps agents? We typically pin a specific node to this group.

![designating a clamps CA](https://cloud.githubusercontent.com/assets/6259/7121830/edfdc0c2-e1dc-11e4-9760-b9708dea0bf2.png)

This node group also assigns the `clamps::master` class to its members.

![clamps::master class](https://cloud.githubusercontent.com/assets/6259/7147134/4b1fe7ee-e2be-11e4-98a7-2ee3cb7f6de4.png)

#### `Clamps - Agent Nodes`

 - `Clamps - Agent Nodes`: which agents will have the clamps module installed? This includes both real nodes (or root agents) and non-root agents.

![identifying clamps agent nodes](https://cloud.githubusercontent.com/assets/6259/7121873/2b7e6546-e1dd-11e4-8092-17745f1831c1.png)

This node group also assigns the `clamps::agent` class to its members.

![clamps::agent class](https://cloud.githubusercontent.com/assets/6259/7147196/c1c607fc-e2be-11e4-986b-fdb398ca44c8.png)

#### `Clamps - Agent Users (non root)`

 - `Clamps - Agent Users (non root)`: which agents are non-root agents?

![non-root agents](https://cloud.githubusercontent.com/assets/6259/7121939/8ba5e1ba-e1dd-11e4-8e4d-dead97ae07a5.png)

This node group also assigns the `clamps` class to its members.

![clamps class](https://cloud.githubusercontent.com/assets/6259/7147269/6e112244-e2bf-11e4-9d8e-75d15613c113.png)


#### `PE MCollective`

 - `PE MCollective`: which agents which will be participating in MCollective (which is not normally the case for non-root agents on a node with an existing root agent)?

![Enabling MCollective](https://cloud.githubusercontent.com/assets/6259/7121978/c5b4dd7a-e1dd-11e4-8370-e2cb199054d7.png)

This node group also assigns the `puppet_enterprise::profile::mcollective::agent` class to its members.

![](https://cloud.githubusercontent.com/assets/6259/7147303/96d13d4a-e2bf-11e4-8b1e-d072db85cd88.png)
