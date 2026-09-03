# Details on the bare-metal 
This project has been developped on a laptop machine with a Fedora 
Linux 44, mounting a *13th Generation Intel® Core™ i7-1365U x 12* and
32GB of RAM.

## Docker
*Docker* was installed with the user oriented package 
*Docker Desktop*, which provides an easy mechanism to manage and
monitor container, but, more important, it does not require root
password or sudo commands. 
The last update was relative to the 4.88.

## Kubernetes
Because *Docker Desktop* has built-in an interface to *Kubernetes* and
two methods for cluster provisioning. The first is a single node
provider very tested and reliable, *kubeadm* that is not suitable for
this project that has the aspiration to manage, at least, two separate
machines. The second one, instead called *kind*, could provide
multiple node, but it seems not able to correctly mount host volumes. 
For these reasons, the best alternative is probably to use a different
approach, leveraging the qualities of the laptop used for this
project: *k3s* on few VMs. Fedora has a native mechanism that is known
as *libvirt*.
