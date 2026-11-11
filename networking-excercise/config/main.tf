# Define App-Network and Subnets
resource "stackit_network" "app_network" {
name = "app-network"
cidr = "10.0.0.0/16"
}

resource "stackit_subnet" "web_tier" {
network_id = stackit_network.app_network.id
name = "web-tier"
cidr = "10.0.1.0/24"
enable_dhcp = true
}

resource "stackit_subnet" "app_tier" {
network_id = stackit_network.app_network.id
name = "app-tier"
cidr = "10.0.2.0/24"
enable_dhcp = true
}

resource "stackit_subnet" "db_tier" {
network_id = stackit_network.app_network.id
name = "db-tier"
cidr = "10.0.3.0/24"
enable_dhcp = true
}

# Define Security Groups
resource "stackit_security_group" "web_sg" {
name = "web-sg"
description = "Rules for web servers"
}

resource "stackit_security_group" "app_sg" {
name = "app-sg"
description = "Rules for app servers"
}

resource "stackit_security_group" "db_sg" {
name = "db-sg"
description = "Rules for db servers"
}

# Security Group Rules for Web Server
resource "stackit_security_group_rule" "web_http" {
security_group_id = stackit_security_group.web_sg.id
direction = "INGRESS"
protocol = "tcp"
port_range_min = 80
port_range_max = 80
remote_ip_prefix = "0.0.0.0/0"
}

resource "stackit_security_group_rule" "web_https" {
security_group_id = stackit_security_group.web_sg.id
direction = "INGRESS"
protocol = "tcp"
port_range_min = 443
port_range_max = 443
remote_ip_prefix = "0.0.0.0/0"
}

resource "stackit_security_group_rule" "web_ssh" {
security_group_id = stackit_security_group.web_sg.id
direction = "INGRESS"
protocol = "ssh"
port_range_min = 22
port_range_max = 22
remote_ip_prefix = "84.84.147.176"
}

# Security Group Rules for App Server
resource "stackit_security_group_rule" "app_http" {
security_group_id = stackit_security_group.app_sg.id
direction = "INGRESS"
protocol = "tcp"
port_range_min = 80
port_range_max = 80
remote_ip_prefix = "10.0.1.0/24"
}

# Security Group Rules for DB Server
resource "stackit_security_group_rule" "db_http" {
security_group_id = stackit_security_group.db_sg.id
direction = "INGRESS"
protocol = "tcp"
port_range_min = 80
port_range_max = 80
remote_ip_prefix = "10.0.2.0/0"
}