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

resource "libvirt_domain" "tinyVM" {
  name   = var.vm_name
  memory = 1024
  vcpu   = 1

  disk {
    volume_id = libvirt_volume.tiny-vol.id
  }

  network_interface {
	hostname = "tinyviemme"
	bridge = "brg-k8s"
	wait_for_lease = false 
  }
  
  # this to enamble the possibility to connect from virsh
  # remember to add a login and a password to the image
  console {
	type = "pty"
	target_port = "0"
	target_type = "serial"
  }
}

resource "libvirt_volume" "tiny-vol" {
  name   = "tiny.qcow2"
  pool   = libvirt_pool.test_pool.name
  source = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
  format = "qcow2"
}

resource "libvirt_pool" "test_pool" {
  name = "test_pool"
  type = "dir"
  target {
	path = "${pathexpand("~")}/.local/share/libvirt/images/test_pool"
  }
}

variable "vm_name" {
  description = "The simples example use of a variable"
  type        = string
  default     = "tinyvm"
}

