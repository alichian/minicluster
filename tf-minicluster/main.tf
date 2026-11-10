# the terraform specification for my setup
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.8.0"
    }
  }
}

# this is needed because is qemu is not explicited and 
# sometime libvirt can use the system one expecially if
# "sudo" is used to start related services
# (like dnsmasq or nfs-server)
provider "libvirt" {
  uri = "qemu:///session?socket=/run/user/1000/libvirt/virtqemud-sock"
}

# this is the map corresponding to one virtual machine
# it ca be expanded easily 
locals {
  machines = {
	#	"tinyvm" = { memory = 1024, vcpu = 1 }
	"planner" = {
	  role        = "server",
	  ip          = "192.168.111.10",
	  memory      = 1024,
	  vcpu        = 2,
	  source_host = "127.0.0.1"
	}
	"worker1" = {
	  role        = "agent",
	  ip          = "192.168.111.11",
	  memory      = 1024,
	  vcpu        = 2,
	  source_host = "127.0.0.2"
	}
	"worker2" = {
	  role        = "agent",
	  ip          = "192.168.111.12",
	  memory      = 1024,
	  vcpu        = 2,
	  source_host = "127.0.0.3"
	}
  }
}



resource "libvirt_pool" "test_pool" {
  name = "test_pool"
  type = "dir"
  target {
	path = "${pathexpand("~")}/.local/share/libvirt/images/test_pool"
  }
}


