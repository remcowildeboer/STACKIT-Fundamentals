# 1. Dedicated virtual network for the TeamBoard workload.
#    Future instances and the load balancer target this same network.
resource "stackit_network" "teamboard" {
  project_id       = var.project_id
  name             = "${local.name}-net"
  ipv4_prefix      = var.network_cidr
  ipv4_nameservers = var.dns_nameservers
  routed           = true # required for public IP / internet egress (updates)
  labels           = local.labels
}

resource "stackit_network_interface" "teamboard" {
  project_id         = var.project_id
  network_id         = stackit_network.teamboard.network_id
  name               = "${local.name}-vm-01-nic"
  security_group_ids = [stackit_security_group.teamboard.security_group_id]
  labels             = local.labels
}

resource "stackit_public_ip" "teamboard" {
  count                = var.assign_public_ip ? 1 : 0
  project_id           = var.project_id
  network_interface_id = stackit_network_interface.teamboard.network_interface_id
  labels               = local.labels
}
