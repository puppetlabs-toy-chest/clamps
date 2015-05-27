CLAMPS is a puppet module designed to help simulate realistic facts and resources during scale testing. We anticipate it being used with  [beaker](https://github.com/puppetlabs/beaker), as we do at Puppet Labs, where we set up clusters of nodes using Amazon EC2.

In order to allow scaling up the number of agents connecting to puppet masters
without the cost and overhead of scaling actual servers or VMs, we instead
generate a set of users on a machine, and have each run a non-root puppet agent
out of that user's home directory. This implies that we cannot manage all
resources on the agent side, but we can at least go through full request and
compile cycles with real agents.

We also generate facts for each non-root agent (up to the number of facts
specified in the configuration), of which some specifiable percentage will have
changing values on each run. Additionally, we generate dynamically changing
`File` resources.

In our testing, an Amazon EC2 `m3.xlarge` node can run about 100 non-root agents with responsive mcollective and puppet runs.

### Fact generation

To compensate for our non-root user agents having virtually no facts, and to
exercise the parts of the stack which need to handle changing fact data (e.g.,
puppetdb), we generate facts and provide changing fact values over the course
of multiple runs here.

We allow the CLAMPS configuration to dictate how many facts are generated, and
what percentage of facts should change over each run. In earlier
implementations, fact randomization generated long random values for every fact,
with every value changing on every run. This meant 100% fact churn, which ends
up trashing the puppetdb fact cache (which ends up doing bad things to
puppetdb).

Since the goal of CLAMPS is to provide load sufficient to exercise a puppet
deployment, and to give confidence that if the running system falls over that
it was not due to the artificial nature of testing, this prior approach was
undesirable.

Fact generation now behaves like this:

 - We extracted a set of real-world fact names, along with the lengths of their
   values, from an agent running on an EC2 node. This allows us to generate
   facts and values with at least the length distributions we could expect to
   see in the real world.

 - We then generate a list of CLAMPS fact names for the non-root agent.
   For a given number of facts per agent (`$num_facts_per_agent` in the
   `clamps::agent` class), the same list of fact names will always be generated.
   These will be in the form clamps_factname_index (e.g., `clamps_uptime_3`).
   This also implies a consistency across agents running independently -- i.e.,
   if two agents are requested to have 100 facts, they will be the same 100
   named facts on each agent.

 - Based upon configuration (`$percent_changed_facts` in the `clamps::agent`
   class), we choose a certain number of facts to receive random values each
   run. The names of the facts which get random values will be consistent
   between runs, while all other facts always have the same values. This will
   also be consistent between agents as well, provided the
   `$num_facts_per_agent` and `$percent_changed_facts` values are set
   identically.

 - By choosing a fixed set of fact names to change we avoid variation in
   churn. The alternative is that if a random, say, 10% of facts are given
   random values, we are either forced to save old fact values between runs to
   avoid changing them (which introduces unwanted storage and serialization
   headaches), or we end up changing old "randomized" values back to some known
   fixed value while we randomize other fact values (which results in an
   inconsistent amount of change between runs).

Our techniques here should also better simulate real-world behavior, where
many facts never change over the lifetime of a node, and certain specific
facts are known to change regularly, across most nodes.

# CLAMPS classes

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
 - `$percent_changed_facts` (Integer): What percentage (0-100) of facts will have new values on each run?
 - `$shuffle_amq_servers` (`Boolean`): Randomize AMQP servers? (default: `true`)
 - `$splay` (`Boolean`):  Enable `--splay` for non-user agent runs? (default: `false`).  See [Configuration: splay](https://docs.puppetlabs.com/references/latest/configuration.html#splay) for puppet agent semantics.
 - `$splaylimit` (`String`): Set the `--splaylimit` parameter for non-user agent runs? (default: unset). Implies `splay`.  See [Configuration: splaylimit](https://docs.puppetlabs.com/references/latest/configuration.html#splaylimit) for puppet agent semantics.

#### `clamps`

Assign `clamps` to the non-root agents on your nodes.

This class accepts the following parameter:

 - `$logic` (`Integer`): relative level of complexity (hence load) to be introduced to the system. Higher values mean more complexity.

## CLAMPS Classification

We make use of CLAMPS by assigning the nodes we're scale testing into CLAMPS-related node groups via the Puppet Enterprise web console (see the "Classification" tab there).

The node groups of interest:

#### `Clamps CA`

 - `Clamps CA`: which node will act as the CA for CLAMPS agents? We typically pin a specific node to this group.

![designating a CLAMPS CA](https://cloud.githubusercontent.com/assets/6259/7121830/edfdc0c2-e1dc-11e4-9760-b9708dea0bf2.png)

This node group also assigns the `clamps::master` class to its members.

![clamps::master class](https://cloud.githubusercontent.com/assets/6259/7147134/4b1fe7ee-e2be-11e4-98a7-2ee3cb7f6de4.png)

#### `Clamps - Agent Nodes`

 - `Clamps - Agent Nodes`: which agents will have the CLAMPS module installed? This includes both real nodes (or root agents) and non-root agents.

![identifying CLAMPS agent nodes](https://cloud.githubusercontent.com/assets/6259/7121873/2b7e6546-e1dd-11e4-8092-17745f1831c1.png)

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
