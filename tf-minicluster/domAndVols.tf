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

  # this is to trigger a replacement when the volume changes,
  # it is added now to build a cascade replacement due
  # to changes happened in the coud-init disk 
  lifecycle {
	replace_triggered_by = [libvirt_volume.machine[each.key]]
  }
  
}

resource "libvirt_volume" "machine" {
  for_each       = local.machines
  name           = "${each.key}.qcow2"
  pool           = libvirt_pool.test_pool.name
  base_volume_id = libvirt_volume.debian-base.id
  size           = 5368709120   # roughtly 5 GB
  format         = "qcow2"

  # this is to trigger a replacement when the coud-init disk is
  # modified
  lifecycle {
	replace_triggered_by = [libvirt_cloudinit_disk.machine-init[each.key]]
  }

}

resource "libvirt_volume" "debian-base" {
  name   = "debian-13.qcow2"
  pool   = libvirt_pool.test_pool.name
  source = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
  format = "qcow2"
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
	mysshkey   = trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))
	myname     = each.key
	role       = each.value.role
	k3stoken   = random_password.k3stoken.result
	planner_IP = local.machines["planner"].ip
  })
  
  meta_data      = templatefile("${path.module}/cloud-init/meta-data.yaml", {
	name = each.key
  })
  
  network_config = templatefile("${path.module}/cloud-init/network.yaml", {
	myaddress = each.value.ip
  })
}

