# minicluster
This is a simple project to play with docker and possibly integrate it
with other modern cloud tools, such as Kubernetes or Terraform.

## Structure 
Following the trace of an old magazine, this small cluster has a
structure different from the usual. Indeed, the *login* and the
*admin* nodes are the same computer in all the cluster that I've been
using since I begin my thesis (quite few years now). 

To be explicit, in this case the structure is the following: 
```text
 +----------+     +-------+     +--------+
 | internet |---->| login |---->| switch |
 +----------+     +-------+     +--------+
                                  |  |  |
                             ------  |  -------
							 |       |        | 
                             V       V        V 
					  +-------+  +-------+ +-------+
	                  | admin |  | comp1 | | comp2 |
					  +-------+  +-------+ +-------+
```
The *admin* will be a dedicated server/container.

## Required 
There are some prerequisite necessary to make this minicluster
properly working:
1. a working DNS services (this will be provided by docker defaults
   modes)
2. distributed directory space among *amin* and the *comp*N nodes
3. some commands propagator like *Kanif* or *pdsh*
4. *SLURM* installed on each nodes that imply
   - running **slurmctld** on *admin*
   - running **slurmd** on each *comp*
   - the same user (normally called in fantasy excess *slurm*) with
     the same UID
5. *munge* installed and configured correctly
