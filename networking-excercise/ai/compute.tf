# 3. VM with SSH key-based access only.
resource "stackit_key_pair" "admin" {
  name       = "${local.name}-admin-key"
  public_key = chomp(file(pathexpand(var.ssh_public_key_path)))
}

resource "stackit_server" "teamboard" {
  project_id        = var.project_id
  name              = "${local.name}-vm-01"
  availability_zone = var.availability_zone
  machine_type      = var.machine_type
  keypair_name      = stackit_key_pair.admin.name

  boot_volume = {
    source_type           = "image"
    source_id             = local.image_id
    size                  = var.boot_volume_size
    delete_on_termination = true # OS disk is disposable; data lives on stackit_volume.data
  }

  network_interfaces = [stackit_network_interface.teamboard.network_interface_id]

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    data_volume_serial = local.data_volume_serial
    data_mount_point   = var.data_mount_point
  })

  labels = local.labels

  lifecycle {
    # A newer "latest" image must not silently replace the production VM.
    ignore_changes = [boot_volume]
  }
}
