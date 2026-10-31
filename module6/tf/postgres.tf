resource "stackit_postgresflex_instance" "scrumlr" {
  project_id      = var.project_id
  name            = "scrumlr"
  acl             = stackit_ske_cluster.scrumlr.egress_address_ranges
  backup_schedule = "0 0 * * *"
  flavor = {
    cpu = 2
    ram = 4
  }
  replicas = 3
  storage = {
    class = "premium-perf6-stackit"
    size  = 5
  }
  version = 17
}

resource "stackit_postgresflex_user" "scrumlr" {
  project_id  = var.project_id
  instance_id = stackit_postgresflex_instance.scrumlr.instance_id
  username    = "scrumlr"
  roles       = ["login", "createdb"]
}

resource "stackit_postgresflex_database" "scrumlr" {
  project_id  = var.project_id
  instance_id = stackit_postgresflex_instance.scrumlr.instance_id
  owner       = stackit_postgresflex_user.scrumlr.username
  name        = "scrumlr"
}

output "postgres_dsn" {
  value = format(
    "postgres://%s:%s@%s:%d/%s",
    stackit_postgresflex_user.scrumlr.username,
    stackit_postgresflex_user.scrumlr.password,
    stackit_postgresflex_user.scrumlr.host,
    stackit_postgresflex_user.scrumlr.port,
    stackit_postgresflex_database.scrumlr.name
  )
  sensitive = true
}
