# Minicluster
This is a simple project to play with docker and possibly integrate it
with other modern cloud tools, such as Kubernetes or Terraform.

## Structure 
Following the trace of an old magazine, this small cluster has a
structure different from the usual. Indeed, the *login* and the
*admin* nodes are the same computer in all the cluster that I've been
using since I begin my thesis (quite few years now). 

To be explicit, in this case the structure is the following: 
```text
 +----------+     +--------+
 | internet |---->| switch |
 +----------+     +--------+
                    |  |  |
               ------  |  -------
               |       |        | 
               V       V        V 
        +-------+  +-------+ +-------+
        | admin |  | comp1 | | comp2 |
        +-------+  +-------+ +-------+
```
The *admin* will be a dedicated server/container.

## Requirements 
There are some prerequisite necessary to make a cluster
properly working:
1. a working DNS services (this will be provided by docker default
   modes)
2. a directory shared among *amin* and the *comp*N nodes to pass
   configuration files and calculation data. 
3. some commands propagator like *Kanif* or *pdsh*
4. *SLURM* installed on each nodes that imply
   - running **slurmctld** on *admin*
   - running **slurmd** on each *comp*
   - the same user (normally called in fantasy excess *slurm*) with
     the same UID
5. *munge* installed and configured correctly 

Note that using pre-configured images of admin and computational nodes
that automatically configure themselves, it is not necessary to use
some *command propagator* like **kanif**or **pdsh**. This become
obvious during the implementation of this mini-cluster, but, I swear,
it was not clear during the design phase. 

## Description
How to this system will be build up il will described in the [detailedDoc.md](./doc/detailedDoc.md).
