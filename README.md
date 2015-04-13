Clamps is a puppet module designed to help simulate realistic facts and resources during scale testing. We anticipate it being used with  [beaker](https://github.com/puppetlabs/beaker), as we do at Puppet Labs, where we set up clusters of nodes using Amazon EC2.

The technique is to generate a random set of users on a machine each running a non-root agent out of the user's home directory. It also generates a random number of facts (from 5 to 75 facts). Since these facts change on each puppet run, this additionally creates puppetdb activity.

In our testing, an Amazon EC2 `m3.xlarge` node can run about 100 users with responsive mcollective and puppet runs.

## Clamps classes

 - Assign `clamps::master` to the master node in the cluster.

 - Assign `clamps::agent` to the root agents on your nodes, as it will install the non root puppet agent accounts, setup their cron job and configuration.

See below for using node classification groups to set things up.

## Clamps Classification

We make use of clamps by assigning the nodes we're scale testing into clamps-related node groups via the Puppet Enterprise web console (see the "Classification" tab there).

The node groups of interest:

 - `Clamps CA`: which node will act as the CA for clamps agents? We typically pin a specific node to this group.

![designating a clamps CA](https://cloud.githubusercontent.com/assets/6259/7121830/edfdc0c2-e1dc-11e4-9760-b9708dea0bf2.png)

 - `Clamps - Agent Nodes`: which agents will have the clamps module installed. This includes both real nodes (or root agents) and non-root agents.

![identifying clamps agent nodes](https://cloud.githubusercontent.com/assets/6259/7121873/2b7e6546-e1dd-11e4-8092-17745f1831c1.png)

 - `Clamps - Agent Users (non root)`: which agents are non-root agents?

![non-root agents](https://cloud.githubusercontent.com/assets/6259/7121939/8ba5e1ba-e1dd-11e4-8e4d-dead97ae07a5.png)

 - `PE MCollective`: Agents which will be participating in MCollective (which is not normally the case for non-root agents on a node with an existing root agent).

![Enabling MCollective](https://cloud.githubusercontent.com/assets/6259/7121978/c5b4dd7a-e1dd-11e4-8370-e2cb199054d7.png)
