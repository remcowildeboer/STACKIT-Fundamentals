resource "stackit_dns_zone" "scrumlr" {
  project_id = var.project_id
  dns_name   = var.dns_name
  name       = "Scrumlr Zone"
}
