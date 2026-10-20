# Terraform

The use of a local provider revealed many unexpected problems. In
particular, the not linear interaction with *libvirt* as a resources
provider. The initial choice was to keep the terraformed minicluser in
a sandbox definitely separated by the host system. The principle of
the maximum security is the core motivation of this and the following
choices. 

## Session vs system QEMU

With all this in mind I added the following specification in my
[main.tf](../tf-minicluster/main.tf):
```
provider "libvirt" {
  uri = "qemu:///session"
}
```
this should guarantee that *terraform* will access only to the user
data and that will not enter in restricted zones of the
system. Unluckily, the interaction is more complex than I believed
before. Even if *terraform* call the libvirtd service to obtain spaces
where write the volumes or images, to obtain domains where build VMs or
to obtain a reserved network, silently libvirtd could "silently"
replay with resources taken from the system emulator generating after
late after permission errors. 
This can be resolved adding a specific directory under
/run/media/$USER and let the virtqemud managing the resources. 

## Networking 

One of the main differences between the two modalities of *libvirt*
providing is the managing of the network: 

	* System mode gives access to the default DNS, mainly because it
      has superuser privileges 
	* Session mode doesn't provide any connection precisely because it
      **does not** have any privileges on networking devices 
.
So every VM built in session mode, even if is running, it is off
line. The solution that still guarantee the security is to create a
specific bridge.
In this specific case I used nmcli to create and manage a bridge
called *brg-k8s* 
```
sudo nmcli connection add type bridge ifname brg-k8s con-name brg-k8s
bridge.stp no ipv4.method shared ipv4.addresses 192.168.111.1/24
ipv6.method disabled
sudo nmcli connection up brg-k8s
```
then, because the connection was not always up I added a dummy
connection an linked it *brg-k8s* 
```
sudo nmcli connection add type dummy ifname dummy-k8s con-name dummy-k8s master brg-k8s slave-type bridge
sudo nmcli connection up dummy-k8s
```
Now the network will be always available and always the same for the rest of
the project. 
In the first instance, I used a terraform to setup just a single
machine. The next section will provide information about how I replaced
the single machine with a three node kubernetes cluster. 

## A simple test case
To begin with something more concrete the first step is to have a
terraform script to configure a tiny infrastructure of just one
machine. This simple machine will be the base for the minicluster
transposition under terraform managing. The requirement are then
basic: a debian linux connected to a network bridge and accessible
from the host. From an oriented object perspective this *tinyVM* is an
ancestor class from which *planer*, *worker1* and *worker2* will
inherit their backbone. 
The structure of *tinyVM* is given in
[tinyVM.tf](../terraform/tinyVM.tf.txt), where a series of
particularity that are probably different from the typical features
found by a *terraform* novice and then they are worth to notice: 
1. the use of *libvirt* as provider and in *session* mode;
2. the use of a volume where the files to initiate a cloud;
   instance (containing the
   [user-data.yaml](../tf-minicluster/cloud-init/user-data.yaml), 
   [network.yaml](../tf-minicluster/cloud-init/network.yaml) and
   [meta-data.yaml](../tf-minicluster/cloud-init/meta-data.yaml); 
3. in the definition of the network interface of the domain, the
   use of `wait_for_lease = false`;
4. the use of a console to connect "directly" through *virsh*
Once verified that it is possible to connect by `ssh` or via `virsh
console`, I will expand incrementally the *tinyVM* to the
*tf-minicluster*.

## Incrementally build the terraform-minicluster
I decided to divide the expansion from *tinyVM* to the
*tf-minicluster* in the following six steps:
	
1. create a copy of the OS image, the nodes images will be just a
   copy of the only downloaded debian image
2. build one copy using `for-each`
3. assign a fixed IP via the cloud initalization file
   `network.yaml` 
4. create the three copies marking the differences
5. configure the *k3s* cluster using what is already described
   in [detailedVagrant.md](detailedVagrant.md)
6. make actionable from the host 
	
### 1. Decoupling images and volumes

Two good reasons interconnected justify the idea of detaching the
image of the *debian linux* from the volume where the system is
stored. The first is the obvious practical simplicity of using, for
each of the virtual machine hosting the *k3s* cluster, exactly the
same OS. The second one, that derive directly from the first, is the
fact that once established that the image is largely sufficient to
download just one copy. This consideration could sound trivial, but
it is worth to mention that the default behaviour of *terraform* is to
download freshly each time the image of a new domain. The for three
machines, three download. 

To decoupling images and volumes I simply introduced a volume where
the effective unique download is done and imposing that the source
will be this new volume.

### 2. Introduction of `for-each`

At this stage, to prepare the multiple copies of the "staminal"
virtual machines, we need to introduce a mechanism that allow to
apply the small variation between them. The construct of choice in
this case is `for_each` and a `locals` list of group of values, a map,
a sort of dictionary in the *Python* sense.

### 3. Fixing the IP

To properly work a *Kubernetes* cluster needs to reach the different
nodes via the internal network. Then it is necessary that each machine
had a fixed IP and this can be easily provided by the cloud
configuration file for the network
[network.yaml](../tf-minicluster/cloud-init/network.yaml).
As mentioned earlier in this page, the bridge has to be already
present and working properly.

### 4. Multiplication and differentiation 

This is the stage where each node receive its role: *planer*, *worker1*
or *worker2*. Even if it is not yet the moment to install *k3s*, it is
necessary to assign a unique ip and to install all the pre-required
packages. The most has been already done in step 3, indeed, after
adding the `locals` map the rest is nothing new. This is the moment to
pave the installation of *k3s* with all the packages necessary to the
installation like `curl`. The most comfortable way to install
prerequisites is to specify it in the
[user-data.yaml](../tf-minicluster/cloud-init/user-data.yaml)

### 5. Configuration of the *k3s* cluster 

### 6. Visible from the host
