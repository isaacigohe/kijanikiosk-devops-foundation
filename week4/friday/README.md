# KijaniKiosk IaC Pipeline (Week 4 Friday)

Terraform creates three servers (api, payments, logs). Ansible configures them to the Week 3 standard. `pipeline.sh` runs both in order and builds the Ansible inventory from the Terraform output.

~~~
terraform apply  ->  server IPs  ->  inventory.ini  ->  ansible-playbook
~~~

## Folder layout

| Path | Purpose |
|---|---|
| terraform/ | Root config: backend.tf, providers.tf, variables.tf, main.tf, outputs.tf |
| terraform/modules/app_server/ | Reusable module for one server (called with for_each for three) |
| ansible/ | kijanikiosk.yml, dns.yml, group_vars/, host_vars/, templates/, generated inventory.ini |
| pipeline.sh | Runs Terraform, writes the inventory, runs Ansible. Exits non-zero on any failure |
| lxd-net-fix.sh | Firewall rules that let LXD containers get an IP inside WSL2 |
| pipeline-run1.log, pipeline-run2.log | Output of two pipeline runs (see Known issue) |
| hardening-decisions.md | Security document written for Nia |
| environment-setup.md | Tool versions and substitutions |
| reflection.md | Answers to the three reflection questions |
| destroy-output.txt | Terraform destroy output |

## How to run it

~~~bash
# 1. start the state storage and create the bucket (first time only)
sudo docker run -d --name rustfs -p 9000:9000 -p 9001:9001 \
  -e RUSTFS_ACCESS_KEY=rustfsadmin -e RUSTFS_SECRET_KEY=rustfsadmin \
  -v rustfs-data:/data rustfs/rustfs:latest
export AWS_ACCESS_KEY_ID=rustfsadmin AWS_SECRET_ACCESS_KEY=rustfsadmin
aws --endpoint-url http://localhost:9000 s3 mb s3://kijanikiosk-tfstate --region us-east-1

# 2. after every WSL restart
./lxd-net-fix.sh

# 3. run the pipeline
sg lxd -c ./pipeline.sh
~~~

## Decisions and why

| Decision | Why | Trade-off |
|---|---|---|
| One app_server module called with for_each | Adding a server means adding one map entry, not copying a resource block | The module interface has to stay small and clear |
| All values (image, key name, server sizes) are variables with descriptions | Nothing is hardcoded inside resource blocks | A few more files to read |
| S3-compatible remote backend | State is shared and not tied to one laptop | See next two rows |
| RustFS instead of MinIO | MinIO's images were removed from Docker Hub and Quay, so docker pull failed | RustFS is newer and less proven. The backend config is the same because it speaks the S3 protocol |
| No state locking | The local S3-compatible storage does not provide it | Two people running at once could corrupt state. Production would use DynamoDB (AWS), GCS locking (GCP) or Consul |
| LXD containers instead of Multipass VMs | In WSL2 the Multipass machines stayed in the Unknown state and never got an IP, even with a 600 second timeout | Containers share the host kernel, so isolation is weaker than a VM |
| lxd-net-fix.sh outside Terraform | Containers only got IPv4 addresses after allowing the LXD bridge in the firewall | A manual step that is not captured as code |
| Ansible variables in group_vars and host_vars, files from templates, restarts only through handlers | Matches the brief and keeps values out of task arguments | More files than a single flat playbook |
| No shell tasks | Idempotent modules (apt, user, file, template, ufw, systemd) report real changes | Some tasks are longer than a one-line command |
| Hardening directives live in the service unit template | The security score is reproduced by code, not by manual steps | A strict unit can stop a service from starting, so it must be tested |
| Environment files under /opt/kijanikiosk/config, not /etc | Challenge D: strict system protection makes much of the system read-only for the service. I checked that the service user can still read the file | None noticed |
| DNS settings written by Ansible (dns.yml) as well as cloud-init | Fresh servers had trouble resolving names. Ansible connects by IP, so it can fix DNS before any package step. dns.yml also forces apt to use IPv4 and fail fast | The same setting exists in two places. Ansible is the one I rely on |
| pipeline.sh uses set -euo pipefail and plan -detailed-exitcode | Any failure stops the script with a non-zero exit code | A pending change after apply is treated as a failure |
| pipeline.sh waits for SSH in a visible loop | A silent wait looked like a freeze | It proves SSH works, not that the server is fully ready |

## Assumptions

I did not have the Week 3 script while writing the playbook. The ports (3000, 3001, 3002), the service accounts (kk-api, kk-payments, kk-logs), the directory layout and the placeholder service (a simple Python web server) are stand-in values and should be checked against Week 3.

## What was proven, and where

| Claim | Evidence |
|---|---|
| Terraform builds three servers and a second plan shows no changes | pipeline-run1.log and pipeline-run2.log |
| The inventory is generated from the Terraform output, not typed by hand | Both logs print inventory.ini after generation |
| The state file persists between runs | Listing of the bucket showed terraform.tfstate |
| Ansible first run changed 13 tasks per host, second run changed 0 | Seen in manual testing against earlier servers. This output is not saved as a log file |
| kk-payments scores 1.2 (target below 2.5) and starts correctly | Same manual testing run, same template |
| The payments environment file can be read by the service user | Same manual testing run |
| Teardown is clean | destroy-output.txt |

## Known issue

In both pipeline logs Ansible stops at the "Install packages" task on freshly built containers, and I did not find the root cause. What I ruled out: SSH works, DNS resolves, and package downloads work when run by hand. Ideas I did not get to test: first-boot background updates holding the package lock, and slow IPv6 attempts before falling back to IPv4. The next step would be a readiness check before Ansible starts (first-boot setup finished, DNS resolving, package mirror reachable).

## Limits of the security posture

See the last section of hardening-decisions.md. In short: no monitoring, default storage credentials, no secrets vault, one SSH key for all servers, containers instead of VMs, and a placeholder service instead of the real application.
