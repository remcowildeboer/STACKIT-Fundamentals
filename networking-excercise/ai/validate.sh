#!/usr/bin/env bash
# Validation proof for the TeamBoard baseline. Run from an APPROVED admin host.
# Usage: ./scripts/validate.sh [path-to-private-key]   -> writes validation-<date>.txt
set -uo pipefail
cd "$(dirname "$0")/.."

KEY="${1:-$HOME/.ssh/id_ed25519}"
IP=$(terraform output -raw access_ip)
USR=$(terraform output -raw ssh_user)
MP=$(terraform output -raw data_mount_point)
SG=$(terraform output -raw security_group_id)
PID=$(terraform output -raw project_id)
OUT="validation-$(date +%Y%m%d-%H%M).txt"
SSH="ssh -i $KEY -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 $USR@$IP"

{
echo "### TeamBoard validation $(date -Is) from $(curl -s https://ifconfig.me || echo unknown)"

echo; echo "== 1. Resource IDs"
terraform output resource_ids

echo; echo "== 2. Security group rules"
if command -v stackit >/dev/null; then
  stackit security-group rule list --security-group-id "$SG" --project-id "$PID"
else
  echo "(stackit CLI not installed - see resource_ids / portal)"
fi

echo; echo "== 3. Port scan from approved host (expect 22/80 open, rest filtered)"
for p in 22 80 443 3306 5432 8080; do
  if nc -z -w3 "$IP" "$p" 2>/dev/null; then echo "port $p: OPEN"; else echo "port $p: closed/filtered"; fi
done

echo; echo "== 4. Password login must be refused (expect: Permission denied (publickey))"
ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password \
    -o BatchMode=yes -o ConnectTimeout=10 "$USR@$IP" true 2>&1 | tail -n1

echo; echo "== 5. Checks on the VM"
$SSH "bash -s -- $MP" <<'REMOTE'
MP="$1"
echo "-- host";            hostnamectl | grep -E 'Static hostname|Operating System'
echo "-- bootstrap";       cat /var/log/teamboard-bootstrap.done 2>/dev/null || echo "NOT FINISHED"
echo "-- disks";           lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS
echo "-- mount";           findmnt "$MP" && df -h "$MP"
echo "-- fstab";           grep " $MP " /etc/fstab
echo "-- data on volume, not OS disk"; findmnt -no SOURCE / ; findmnt -no SOURCE "$MP"
echo "-- sshd effective";  sudo sshd -T | grep -E '^(passwordauthentication|permitrootlogin|pubkeyauthentication|kbdinteractiveauthentication) '
echo "-- listening ports"; sudo ss -tlnp | awk 'NR==1 || /LISTEN/'
echo "-- host firewall";   sudo ufw status verbose
echo "-- updates";         systemctl is-enabled unattended-upgrades; cat /etc/apt/apt.conf.d/20auto-upgrades
echo "-- web";             curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost/ ; curl -s http://localhost/healthz
REMOTE

echo; echo "== 6. Web from approved host"
curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://$IP/"
} 2>&1 | tee "$OUT"

echo; echo "Saved to $OUT"
echo "NEGATIVE TEST (manual): from a NON-approved network run 'nc -vz -w5 $IP 22' -> must time out."
