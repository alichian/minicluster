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

resource "libvirt_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "libvirt_container" "nginx" {
  image = libvirt_image.nginx.image_id
  name  = var.container_name
  ports {
    internal = 80
    external = 8080
  }
}

variable container_name {
  description = "The simples example use of a variable"
  type = string
  default = "nginxCont"
}
