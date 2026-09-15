# Detailed description

In this project I choose to use a minimal *debian-slim* image. 
Then there are a list of required packages: 
1. *ssh* 
2. *munge* and the lib used by *slurm* during compilation 
3. *slurm* and its configuration (look [here](./doc/slurm_config.md))

## Communication
Communication between nodes can be done by the internal bridge network
automagically created by **docker**. The use of IPs can be avoided if 
during the container launch is used the *--name* option.

This is implemented with:
```
docker network create -d bridge slurm-net
```
Consider also that, because **slurm** needs a series of specific names
for each machine it is necessary to add also the --hostname flag when
the containers are launched.

## Shared volumes
The implementation of *slurm* can be done in the directory of the
login machine. Then admin and the computational nodes will use
different configuration for their respective daemons. Only in this way
it is possible to guarantee the uniformity of the installation. 

In any case the best option in this case seems to be the creation of a
generic volume that will be mounted on each machine.

This is implemented with: 
```
docker volume create shared-data
```
Note that there is another advantage with shared volumes. If some
adjustments are required in slurm.conf, it is possible to relaunch the
same container that automatically will make the update of slurm.conf.

For the sake of simplicity, the *share-data* directory in this project
is mounted on the */temp* directory of the containers. This means that
there are potentially some security issue that are not acceptable in a
production run, but in this *proof of concept* is a quick and dirty
solution. 

## Authentication
Authentication works at two level: *ssh* and *munge*.
- *ssh*, with the typical ssh-key shared between all the minicluster
  machines, provide the authentication to monitoring manually the
  system;
- *munge*, it is the default authentication mechanism to let slurm
  correctly works
  
### ssh-key generation
To create the ssh-keys we use the usual command :
```sh-keygen -t ed25519 -f ./shared-data/slurm-rsa -N ""```

### munge-key generation
To create the munge-key you do not need to have *munge* installed on
your linux machine. The following command is sufficient:
```dd if=/dev/urandom bs=1 count=1024 of=./shared-data/munge.key```
 
## Orchestration 
Even if this is a system with a simple structure, the use of an
orchestrator it is already necessary. But before to dive in Kubernetes
the use of docker-compose is a good compromise to begin with. 

Despite the elementary structure of this system, some sort of
orchestration is very useful. But it can be understood and appreciate
only after debugging and launching: 
 * the master node
 * two calculation node
 * an internal network bridge
several times, where the commands begin to be quite long and
complex. For example, just to start one calculation node, you end up with lines
like this : 
```
 docker run -d \
-v $(pwd)/shared-data:/tmp/shared-data:ro \
--network slurm-net \
--name node001 \
--hostname node001 \
minicla-node:latest
```
For this motivation, in the long run is it definitely interesting to
have a *docker-compose.yml* that resume all the needs in a declarative
manner instead to have a long series of entangled scripts. Moreover
this will be useful when a CI/CD pipeline will be applied to this
project to make it closer to the modern DevOps philosophy. 
The final version of this magic file is [here](../dockerfiles/docker-compose.yml)
 
## Particularity
There is an important difference between the typical docker project,
and this one : the nodes of a cluster have the aspiration to be
complete machines, not clusters. This is just an excuse to play around
with docker. The more natural implementation would use at least
virtual machines. 

But, despite this considerations, These nodes are **not** virtual
machines, but just containers that normally run one application. 
However, here it is required that a **sshd** daemon runs in
parallel with **slurmd** (or **slurmctld**) and **munged** daemons.
In order to have a properly working node. The easiest solution is to
have a script as **ENTRYPOINT**, that launches two of the overly
mentioned daemon something like the following script
```
#!/bin/bash

# Start SSH daemon in the background
echo "Starting SSH..."
/usr/sbin/sshd

# Start Munge daemon in background
su -s /bin/bash -c "/usr/sbin/munge"

# Start Slurm daemon in the foreground (this keeps the container alive)
echo "Starting Slurmd..."
exec /usr/sbin/slurmd -D
```
How this is implemented in practice in this project can be read in the
actual entrypoint scripts
[admin.entrypoint.sh](doc/admin.entrypoint.sh) and [node.entrypoint.sh](doc/node.entrypoint.sh).

## Kubernetes migration
To have some more realistic system to play with, the best option is to
create a virtualized **Kubernetes** cluster. The details on how this
was configured on my laptop through **vagrant** is
[here](detailedVagrant.md). This virtualized node will result very
interesting when *Flux CD* and some monitoring tools will be
integrated in the project. 

With this said, the migration to *kubernetes* will be accomplished
following with a stepwise strategy : 
	1. propose a direct deployment of the admin, node001 and node002
	   each of them with a defined service;
	2. shift to a more dynamic structure where the number of
       calculation nodes can be redefined *on-the-fly*; 
	   
### 1. Stemming form docker-compose.yml
In this first phase, I decided to transpose the
[docker-compose.yml](../dockerfiles/docker-compose.yml) keeping each
deployment completely bound to its relative service. For this reason I
ends up with three yaml files: [slurm-admin.yaml](../k8s/slurm-admin.yaml),
[slurm-node001.yaml](../k8s/slurm-node001.yaml) and
[slurm-node002.yaml](../k8s/slurm-node002.yaml). This is of course not
the best solution, but the best staring point: it is not necessary to
change nothing in what was already tested and verify when the docker
compose was prepared.
It is worth to note that here, diversely to the typical use of pods in
*Kubernetes*, each service has a defined name that is used then by the
internal DNS to lets *slurmctld* on the admin find exactly the
required node. Moreover, these Service *metadata.name* reflect then
the hostname defined in [slurm.conf](../shared-data/slurm.conf).

### 2. StatefulSet + headless Service
Now we are ready to shift to a more flexible architecture. In order to
do this, it necessary to :

	1. shift to the more suitable kind *StatefulSet* and the use of a
       *headless Service*, in this way the cluster is no more
       restricted to have just two computation nodes, but is now
       scalable; 
	2. in slurm.conf change the slurm hostnames of a computational
       node in order to match the flexibly of the *Statefulset*
       architecture and, in the same file also, add *NodeAddr* item in
       the definition of the node ressources (see the new version of
       [slurm.conf](.k8s/slurm.conf)); 
	3. modify the [node.entrypoint.sh](./k8s/node.entrypoint.sh) and
       [admin.entrypoint.sh](./k8s/admin.entrypoint.sh) to recover the
       actual ${HOSTNAME}; 
	4. pass from the shared-data directory to a *ConfigMap* for
       slurm.conf now recasted in the pod manifesto
       [slurm-conf.yaml](./k8s/slurm-conf.yaml)



