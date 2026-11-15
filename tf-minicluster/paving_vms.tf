
# this is a triggered action to import the images to each VM 
resource "terraform_data" "prepare_vm" {
  for_each = local.machines

  # This a very clever way to track changes in shared-data :
  # the hashing (sha1) of the concatenation of the hash (filesha1)
  # of each file (fileset) inside shared-data
  triggers_replace = sha1(join("", [
    for f in fileset("${path.module}/shared-data", "**") :
    filesha1("${path.module}/shared-data/${f}")
  ]))

  connection {
    type        = "ssh"
    host        = each.value.ip
    user        = "debian"
    #private_key = file(var.ssh_key)
	#private_key = trimspace(file(pathexpand("~/.ssh/id_ed25519")))
	agent       = true
  }

  provisioner "remote-exec" {
	inline = [
	  "sudo rm -rf /tmp/shared-data"
	]
  }
  
  # copying from the host to the /var/tmp/shared-data the configuration files
  # used by the entrypoint scripts (we need to change them)
  provisioner "file" {
    source      = "${path.module}/shared-data"
    destination = "/var/tmp"
  }

  # coping the images to the VMs
  provisioner "file" {
	source      = "${path.module}/images"
	destination = "/var/tmp"
  }
  
  # uploading the images  in the 
  provisioner "remote-exec" {
    inline = [
      "for t in /var/tmp/images/minicla-*.tar; do sudo k3s ctr images import $t; done"
    ]
  }

  depends_on = [libvirt_domain.machine]
}
