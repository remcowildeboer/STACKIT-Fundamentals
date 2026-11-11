terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = "0.119.0" # Replace x.y.z with the desired version
    }
  }
}

provider "stackit" {
  service_account_key_path = var.service_account_key_path
  default_region           = var.region
  # Authentication uses the recommended Key-Flow (see Module 2).
  # The deprecated Token-Flow (service_account_token) should only be used for legacy setups.
}

resource "stackit_network" "example_network" {
  project_id         = var.project_id
  name               = "terraform-demo-network"
  ipv4_prefix_length = 24
}

resource "stackit_network_interface" "example_nic" {
  project_id = var.project_id
  network_id = stackit_network.example_network.network_id
}

resource "stackit_server" "example_server" {
  project_id         = var.project_id
  name               = "demo-server"
  machine_type       = var.machine_type # e.g. "g2i.1"
  network_interfaces = [stackit_network_interface.example_nic.network_interface_id]

  boot_volume = {
    size        = 64
    source_type = "image"
    source_id   = var.image_id
  }
}
