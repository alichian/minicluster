# Terraform

The use of a local provider revealed many unexpected problems. In
particular, the not linear interaction with *libvirt* as a resources
provider. The initial choice was to keep the terraformed minicluser in
a sandbox definitely separated by the host system. The principle of
the maximum security is the core motivation of this and the following
choices. 

## Session vs system QEMU

With this in mind I added the following specification in my
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
Now it will be always available and always the same for the rest of
the project.
