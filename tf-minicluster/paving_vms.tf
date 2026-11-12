
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

  # copying from the host to the /tmp/shared-data
  provisioner "file" {
    source      = "${path.module}/shared-data"
    destination = "/tmp"
  }

  # tarballs -> k3s containerd
  provisioner "file" {
    source      = "${path.module}/../vagrant/"
    destination = "/tmp"
  }
  provisioner "remote-exec" {
    inline = [
      "for t in /tmp/minicla-*.tar; do sudo k3s ctr images import $t; done",
    ]
  }

  depends_on = [libvirt_domain.machine]
}
