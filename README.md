# Minicluster
This project is the transposition of a tiny real-world HPC cluster
into a fully containerized environment. The cluster architecture has
the typical structure of a computing cluster for scientific purpose:
it include a masternode (*admin*), two computational nodes
(*node001* and *node002*) and a queue managing system (*SLURM*).
This structure is the backbone of real cluster that I manage daily in my
professional life in a theoretical chemistry team.
The initial structure of a pure *Docker* architecture is intended as
an evolving bench where apply, step by step, a number of modern DevOps
tools (*Kubernetes*, *Terraform*, *GitOps* and *Grafana/Prometheus*). 
The actual status of the project evolution can be find in the file
[status.md](./doc/status.md). 

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
2. a directory shared among *admin* and the *comp*N nodes to pass
   configuration files and calculation data. 
3. some commands propagator like *Kanif* or *pdsh*
4. *SLURM* installed on each nodes that imply
   - running **slurmctld** on *admin*
   - running **slurmd** on each *comp*
   - the same user (normally called in fantasy excess *slurm*) with
     the same UID
5. *munge* installed and configured correctly 

Note that using pre-configured images of admin and computational nodes
that automatically configure themselves in a containerized way, it is
not necessary to use some *command propagators* like **kanif**or
**pdsh**. This become clear during the implementation and it was not
anticipated during the design phase. In other word the "language of
containers" allowed an unexpected shortcut when I was rephrasing the
cluster from the "language of bare-metal".

## Description
The detailed information on what this minicluster contains can be find
in the file [detailedDoc.md](./doc/detailedDoc.md). Here it can be
find also the translation to *Kubernetes*.
The detailed description of the hardware used to develop this project
and its implication on the used tools is instead in the file [hardware.md](./doc/hardware.md) 
