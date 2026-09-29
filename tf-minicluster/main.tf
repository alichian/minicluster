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
  uri = "qemu:///session"
}

resource "libvirt_domain" "tinyVM" {
  name   = var.vm_name
  memory = 1024
  vcpu   = 1

  disk {
    volume_id = libvirt_volume.tiny-vol.id
  }
}

resource "libvirt_volume" "tiny-vol" {
  name   = "tiny.qcow2"
  pool   = "default"
  source = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
  format = "qcow2"
}


variable "vm_name" {
  description = "The simples example use of a variable"
  type        = string
  default     = "tinyvm"
}
