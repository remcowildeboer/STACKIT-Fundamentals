# Networking in the STACKIT Cloud

**Task**

Design a secure, three-tier network architecture for a typical web application with web, application, and database tiers.

The virtual network should have three subnets for each tier:
- Web Tier: Publicly accessible for web servers
- App Tier: Private subnet for application servers
- DB Tier: Isolated subnet for database servers

IP address ranges:
- Virtual Network CIDR: 10.0.0.0/16
- Web Tier: 10.0.1.0/24
- App Tier: 10.0.2.0/24
- DB Tier: 10.0.3.0/24

Security Group rules:
- Web Tier: Allow HTTP/HTTPS from anywhere, SSH only from trusted IPs
- App Tier: Allow access only from the Web Tier
- DB Tier: Allow access only from the App Tier

**Solution**

The terraform configurations for all the resources required to create and configure above mentioned networks, subnets and security rules are available in [config/main.tf](./config/main.tf).

> Disclaimer: Provisioning and correct functioning of these networking resources and security rules have not been verified due to the limitation of not having a customer account on STACKIT Cloud.