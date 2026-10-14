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
	"planner" = { ip = "192.168.111.10", memory = 1024, vcpu = 2, source_host = "127.0.0.1" }
	"worker1" = { ip = "192.168.111.11", memory = 1024, vcpu = 2, source_host = "127.0.0.2" }
	"worker2" = { ip = "192.168.111.12", memory = 1024, vcpu = 2, source_host = "127.0.0.3" }
  }
}

resource "libvirt_domain" "machine" {
  for_each  = local.machines
  name   = each.key
  memory = each.value.memory
  vcpu   = each.value.vcpu
  autostart = false
  running = true
  
  disk {
    volume_id = libvirt_volume.machine[each.key].id
  }

  network_interface {
	hostname = "tinyviemme"
	bridge = "brg-k8s"
	# indeed with a session qemu provisioning the bridge cannot be managed
	wait_for_lease = false 
  }
  
  # this to enamble the possibility to connect from virsh
  # remember to add a login and a password to the image
  console {
	source_host = each.value.source_host
	type        = "pty"
	target_port = "0"
	target_type = "serial"
  }

  # this is the initialisator disk
  cloudinit = libvirt_cloudinit_disk.machine-init[each.key].id
}

# this a sort of floppydisk initalizator : is read
# and executed only once, at the creation
resource "libvirt_cloudinit_disk" "machine-init" {
  for_each  = local.machines
  name      = "${each.key}.iso"
  pool      = libvirt_pool.test_pool.name
  # the use of templatefile() and file() is a simple way to
  # validate clearly the indentation of yaml files 
  user_data = templatefile("${path.module}/cloud-init/user-data.yaml", {
	mysshkey = trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))
  })
  meta_data      = file("${path.module}/cloud-init/meta-data.yaml")
  network_config = templatefile("${path.module}/cloud-init/network.yaml", {
	myaddress = each.value.ip
  })
}

resource "libvirt_volume" "machine" {
  for_each       = local.machines
  name           = "${each.key}.qcow2"
  pool           = libvirt_pool.test_pool.name
  base_volume_id = libvirt_volume.debian-base.id
  size           = 5368709120   # roughtly 5 GB
  format         = "qcow2"
}

resource "libvirt_volume" "debian-base" {
  name   = "debian-13.qcow2"
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


