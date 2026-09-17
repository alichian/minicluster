# the terraform specification for may setup
terraform {
  required_providers {
	libvirt = {
	  source = "dmacvicar/libvirt"
	  version = "~> 0.8"
	}
  }
}
