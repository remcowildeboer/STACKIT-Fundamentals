variable "service_account_key_path" {
  description = "Path to the Service Account Key (JSON) for the STACKIT Terraform Provider"
  type        = string
  default     = "c:/temp/terraform-demo/sa-key.json"
}

variable "region" {
  description = "Region in the STACKIT Cloud"
  type        = string
  default     = "eu01"
}

variable "project_id" {
  description = "STACKIT project ID in which the resources are created"
  type        = string
  default     = "<project-id>"
}

variable "image_id" {
  description = "ID of the OS image used for the server's boot volume"
  type        = string
  default     = "07f1c7e4-23ff-4060-977f-3c4b168dee5d"
}

variable "machine_type" {
  description = "Machine type (flavor) of the server, e.g. g2i.1"
  type        = string
  default     = "g2i.1"
}