# 2. Hardened security group (stateful: return traffic is allowed automatically).
#    Default = deny. Only the rules below are opened.
resource "stackit_security_group" "teamboard" {
  project_id  = var.project_id
  name        = "${local.name}-sg"
  description = "TeamBoard: SSH only from approved admin ranges, HTTP(S) only from approved ranges."
  stateful    = true
  labels      = local.labels
}

# --- Ingress ----------------------------------------------------------------------
resource "stackit_security_group_rule" "ssh_admin" {
  for_each = toset(var.admin_cidrs)

  project_id        = var.project_id
  security_group_id = stackit_security_group.teamboard.security_group_id
  description       = "SSH from approved admin range ${each.value}"
  direction         = "ingress"
  ether_type        = "IPv4"
  ip_range          = each.value
  protocol          = { name = "tcp" }
  port_range        = { min = 22, max = 22 }
}

resource "stackit_security_group_rule" "icmp_admin" {
  for_each = toset(var.admin_cidrs)

  project_id        = var.project_id
  security_group_id = stackit_security_group.teamboard.security_group_id
  description       = "ICMP (diagnostics) from admin range ${each.value}"
  direction         = "ingress"
  ether_type        = "IPv4"
  ip_range          = each.value
  protocol          = { name = "icmp" }
}

resource "stackit_security_group_rule" "web" {
  for_each = {
    for pair in setproduct(var.web_allowed_cidrs, var.web_ports) :
    "${pair[0]}-${pair[1]}" => { cidr = pair[0], port = pair[1] }
  }

  project_id        = var.project_id
  security_group_id = stackit_security_group.teamboard.security_group_id
  description       = "Web ${each.value.port} from ${each.value.cidr}"
  direction         = "ingress"
  ether_type        = "IPv4"
  ip_range          = each.value.cidr
  protocol          = { name = "tcp" }
  port_range        = { min = each.value.port, max = each.value.port }
}

# --- Egress (only what the VM needs: DNS, NTP, package repos/HTTPS) ----------------
# NOTE: if STACKIT created default "allow all egress" rules on this group, remove them
# (portal/CLI) so only the rules below remain.
locals {
  egress_rules = {
    dns-udp = { protocol = "udp", port = 53 }
    dns-tcp = { protocol = "tcp", port = 53 }
    ntp     = { protocol = "udp", port = 123 }
    http    = { protocol = "tcp", port = 80 }
    https   = { protocol = "tcp", port = 443 }
  }
}

resource "stackit_security_group_rule" "egress" {
  for_each = local.egress_rules

  project_id        = var.project_id
  security_group_id = stackit_security_group.teamboard.security_group_id
  description       = "Egress ${each.key}"
  direction         = "egress"
  ether_type        = "IPv4"
  ip_range          = "0.0.0.0/0"
  protocol          = { name = each.value.protocol }
  port_range        = { min = each.value.port, max = each.value.port }
}
