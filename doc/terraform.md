# Terraform

The use of a local provider revealed many unexpected problems. In
particular, the not linear interaction with *libvirt* as a resources
provider. The initial choice was to keep the terraformed minicluser in
a sandbox definitely separated by the host system. The principle of
the maximum security is the core motivation of this choice. 
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

But the problems are not finish yet. Indeed, libvirtd in session mode
does not provide by default a local network. So every VM built in
session mode, even if is running, it is off line. The solution that
still guarantee the security is to create a specific bridge.
