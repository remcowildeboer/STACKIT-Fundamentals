resource "stackit_observability_instance" "scrumlr" {
  project_id                             = var.project_id
  name                                   = "scrumlr"
  # Observability-Starter-EU01 may be enough for a short trial, but the metric samples (per minute) limit is quickly reached with our example.
  plan_name                              = "Observability-Basic-EU01"
}

resource "stackit_observability_credential" "cluster" {
  project_id  = var.project_id
  instance_id = stackit_observability_instance.scrumlr.instance_id
}

output "o11y_grafana_url" {
  value = stackit_observability_instance.scrumlr.grafana_url
}

output "o11y_logs_push_url" {
  value = stackit_observability_instance.scrumlr.logs_push_url
}

output "o11y_metrics_push_url" {
  value = stackit_observability_instance.scrumlr.metrics_push_url
}

output "o11y_cluster_user" {
  value = stackit_observability_credential.cluster.username
}

output "o11y_cluster_password" {
  value = stackit_observability_credential.cluster.password
  sensitive = true
}
