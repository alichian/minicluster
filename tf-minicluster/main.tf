# the terraform specification for may setup
terraform {
  required_providers {
	libvirt = {
	  source = "dmacvicar/libvirt"
	  version = "~> 0.8"
	}
  }
}

# this is needed because is qemu is not explicited
# sometime libvirt can use the system one expecially if
# "sudo" is used to start related services
# (like dnsmasq or nfs-server)
provider "libvirt" {
  uri = "qemu:///session"
}

