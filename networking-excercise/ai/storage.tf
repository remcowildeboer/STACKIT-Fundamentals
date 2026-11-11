# 4. Separate data volume (application data never on the OS disk).
resource "stackit_volume" "data" {
  project_id        = var.project_id
  name              = "${local.name}-data"
  availability_zone = var.availability_zone
  size              = var.data_volume_size
  performance_class = var.data_volume_performance_class
  description       = "TeamBoard application data, mounted at ${var.data_mount_point}"
  labels            = local.labels

  lifecycle {
    # Data must survive VM replacement and accidental 'terraform destroy'.
    # For a lab teardown: set to false (or 'terraform state rm') first.
    prevent_destroy = true
  }
}

resource "stackit_server_volume_attach" "data" {
  project_id = var.project_id
  server_id  = stackit_server.teamboard.server_id
  volume_id  = stackit_volume.data.volume_id
}
