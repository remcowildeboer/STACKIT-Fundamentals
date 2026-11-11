# TeamBoard – STACKIT production-ready baseline (Terraform)

Herbruikbare baseline voor één Linux-VM (nginx + app) op STACKIT, met een aparte datavolume, least-privilege security group en voorbereiding op updates, backups en een latere Load Balancer.

## Architectuur

```
 Corporate VPN / bastion (admin_cidrs) ──22/tcp──┐
 Corporate range (web_allowed_cidrs) ──80,443────┤
                                                 ▼
                                   [ Security group teamboard-prod-sg ]  (stateful, default deny)
                                                 │
   stackit_network teamboard-prod-net 10.20.0.0/24
        └─ NIC ── VM teamboard-prod-vm-01 (Ubuntu 24.04, g2i.2)
                    ├─ boot volume 20 GB   → alleen OS (wegwerpbaar)
                    └─ data volume 50 GB   → /data  (ext4, fstab op UUID, prevent_destroy)
   Egress: alleen DNS 53, NTP 123, HTTP/HTTPS 80/443
   Ops:    unattended-upgrades + STACKIT update schedule (wekelijks) + backup schedule (dagelijks, 14 d)
```

## Bestanden

| Bestand | Inhoud |
|---|---|
| `versions.tf` | provider `stackitcloud/stackit` |
| `network.tf` | taak 1: eigen netwerk, NIC, public IP |
| `security.tf` | taak 2: security group + rules (SSH alleen van admin-ranges, beperkte egress) |
| `compute.tf` | taak 3: key pair + VM (alleen SSH-keys) |
| `storage.tf` | taak 4: datavolume + attach |
| `templates/cloud-init.yaml.tftpl` | OS-hardening, mount `/data`, nginx, ufw, fail2ban |
| `operations.tf` | update- en backupschedules |
| `outputs.tf` | resource-ID's + kant-en-klare deployment note |
| `scripts/validate.sh` | taak 5: validatiebewijs |

## Uitrollen

```bash
cp terraform.tfvars.example terraform.tfvars   # project_id, admin_cidrs, web_allowed_cidrs invullen
terraform init
terraform plan -out tfplan
terraform apply tfplan
terraform output deployment_note
./scripts/validate.sh ~/.ssh/id_ed25519        # na ±3-5 min (cloud-init)
```

Voorwaarden: service account met rechten op het project (key-JSON), en een SSH-keypair. `admin_cidrs` wordt door Terraform gevalideerd: `0.0.0.0/0` wordt geweigerd.

## Ontwerpkeuzes

**Least privilege.** De security group is stateful en staat standaard niets toe. Ingress alleen 22/tcp + ICMP vanaf `admin_cidrs` en 80/443 vanaf `web_allowed_cidrs`. Egress is beperkt tot wat de VM nodig heeft voor updates en tijd/DNS. Controleer na de eerste apply of STACKIT standaard "allow all egress"-regels heeft aangemaakt en verwijder die als dat zo is. ufw op de VM is een tweede laag (alleen 22/80/443); de security group bepaalt *wie* mag.

**SSH-hardening.** Alleen public-key-login, geen root-login, geen wachtwoorden, MaxAuthTries 3, fail2ban actief.

**Data los van de VM.** Het datavolume wordt via `/dev/disk/by-id/virtio-<eerste 20 tekens volume-ID>` gevonden, alleen geformatteerd als het nog leeg is en op UUID in `/etc/fstab` gezet met `nofail`. Daardoor kan de VM vervangen worden (`terraform apply -replace=stackit_server.teamboard`) en koppelt de nieuwe VM dezelfde data weer aan zonder te formatteren. `prevent_destroy` beschermt het volume tegen een per ongeluk `terraform destroy`. nginx start pas als `/data` gemount is (`RequiresMountsFor`).

**Updates & backups.** unattended-upgrades installeert security-updates dagelijks; de STACKIT update schedule draait wekelijks patches binnen een onderhoudsvenster (incl. eventuele reboot). De STACKIT backup schedule maakt dagelijks backups van alle gekoppelde volumes (OS + data). Labels (`app`, `environment`, `backup`) maken latere backup-/policy-automatisering eenvoudig.

**Image-pinning.** De VM negeert wijzigingen in `boot_volume`, zodat een nieuwe "latest" Ubuntu-image de productie-VM niet stilletjes vervangt. Zet voor productie bij voorkeur een vaste `image_id`.

## Validatie (taak 5)

`scripts/validate.sh` legt de volgende bewijzen vast in `validation-<datum>.txt`:

1. Resource-ID's (netwerk, SG, server, volume, NIC, public IP).
2. Security-group-regels via de STACKIT CLI.
3. Poortscan vanaf de toegestane host: 22 en 80 open, overige poorten (3306, 5432, 8080) gefilterd.
4. Wachtwoordlogin wordt geweigerd (`Permission denied (publickey)`).
5. Op de VM: `lsblk`, `findmnt /data`, `df -h /data`, fstab-regel, root op `vda` vs. data op `vdb`, effectieve sshd-instellingen (`sshd -T`), luisterende poorten, ufw-status, unattended-upgrades, nginx `/healthz`.
6. HTTP 200 vanaf de toegestane host.

Handmatige negatieve test: vanaf een **niet**-goedgekeurd netwerk (bijv. mobiele hotspot) `nc -vz -w5 <ip> 22` → time-out. Persistentietest: `sudo reboot`, daarna opnieuw `findmnt /data`.

## Opschalen achter een Load Balancer

1. Maak per extra instance een NIC (zelfde netwerk + security group), server en eigen datavolume (`count`/`for_each`, of zet compute/storage in een module).
2. Voeg een `stackit_loadbalancer` toe in hetzelfde netwerk met `disable_security_group_assignment = true` en zet de VM's als targets (`stackit_network_interface.*.ipv4`).
3. Vervang de web-regels op CIDR door één regel met `remote_security_group_id = stackit_loadbalancer.<naam>.security_group_id` op poort 80/443; haal daarna de public IP's van de VM's weg en laat SSH via een bastion lopen.
4. Gedeelde applicatiestate hoort bij meerdere instances niet op losse block volumes: verplaats die naar een managed database (bijv. STACKIT PostgreSQL Flex) en/of Object Storage. Het datavolume blijft dan voor lokale data/cache.

## Opruimen (alleen lab)

Zet `prevent_destroy = false` in `storage.tf` en draai `terraform destroy`.
