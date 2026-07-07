# Detailed description

In this project I choose to use a minimal *debian-slim* image. 
Then there are a list of required packages: 
1. *ssh*
2. *pdsh* and its configuration that can be not straightforward (look
   [here](./doc/pdsh_config.md))
3. *munge* and the lib used by *slurm* during compilation 
4. *slurm* and its configuration (look [here](./doc/slurm_config.md))

## Communication
Communication between nodes can be done by the internal bridge network
automagically created by **docker**. The use of IPs can be avoided if
during the container launch is used the *--name* option. 

This is implemented with:
```
docker network create -d bridge slurm-net
```

## Shared volumes
The implementation of *slurm* can be done in the directory of the
login machine. Then admin and the computational nodes will use
different configuration for their respective demons. Only in this way
it is possible to guarantee the uniformity of the installation. 

In any case the best option in this case seems to be the creation of a
generic volume that will be mounted on each machine.

This is implemented with: 
```
docker volume create shared-data
```

## Orchestration 
Even if this is a system with a simple structure, the use of an
orchestrator it is already necessary. But before to dive in Kubernetes
the use of docker-compose is a good compromise. 

Because, just for launch one calculation node, you end up with lines
like this one :
```
docker run -d \
	--name node001 \
	--network slurm-net \
	-v shared-data:/shared \
	debian:slim /bin/bash 
```
For this motivation is it more interesting to have a
docker-compose.yml that resume all the needs in a declarative manner
instead to have a long series of entangled scripts.
The final version of this magic file is [here](../dockerfiles/docker-compose.yml)

## Particularity
There is a not obvious problem. These machines are **not** virtual
machines, but just containers. This means that their are imagined as a
one shot application services. Then if I need a sshd demon running in
parallel with slurmd demon it is tricky to have a well working
machine. 
The solution is just a script as **ENTRYPOINT**, something like 
```
#!/bin/bash

# Start SSH daemon in the background
echo "Starting SSH..."
/usr/sbin/sshd

# Start Slurm daemon in the foreground (this keeps the container alive)
echo "Starting Slurmd..."
exec /usr/sbin/slurmd -D
```
