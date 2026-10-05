#!/bin/bash
# runs terraform then ansible, ips come from terraform output (lxd path)
set -euo pipefail
cd "$(dirname "$0")"

export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-rustfsadmin}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-rustfsadmin}
export ANSIBLE_TIMEOUT=10

echo "== terraform =="
terraform -chdir=terraform init -input=false
terraform -chdir=terraform apply -auto-approve -input=false
# exit code 2 means changes are still pending
terraform -chdir=terraform plan -detailed-exitcode -input=false

echo "== inventory =="
IPS=$(terraform -chdir=terraform output -json server_ips)
{
  echo "[kijanikiosk]"
  for s in api payments logs; do
    echo "kijanikiosk-$s ansible_host=$(echo "$IPS" | jq -r ".$s")"
  done
} > ansible/inventory.ini
cat ansible/inventory.ini

echo "== ansible =="
cd ansible
# wait until all servers accept ssh, show progress
ok=0
for i in $(seq 1 20); do
  if ansible kijanikiosk -m ping > /dev/null 2>&1; then ok=1; break; fi
  echo "waiting for ssh... ($i/20)"
  sleep 5
done
if [ "$ok" -ne 1 ]; then
  echo "ERROR: servers not reachable over ssh"
  ansible kijanikiosk -m ping || true
  exit 1
fi
ansible-playbook kijanikiosk.yml
