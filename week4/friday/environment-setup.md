# Environment Setup

Path used: primary local path with two substitutions (explained below). No cloud account was used.

| Tool | Version |
|---|---|
| OS | Ubuntu 26.04.1 LTS on WSL2 (kernel 6.18.33.2-microsoft-standard-WSL2) |
| Terraform | Terraform v1.16.4 |
| Terraform LXD provider | terraform-lxd/lxd v2.7.1 |
| Ansible | ansible [core 2.21.4] |
| LXD | 5.21.8-3a06799 |
| Docker | Docker version 29.1.3, build 29.1.3-0ubuntu4.1 |
| State storage | RustFS, image rustfs/rustfs:latest (digest sha256:1803faef57627e2d9c2e7d89d655d712ddded5389040054987163043fecb6a3c) |
| jq | jq-1.8.1 |
| Git | git version 2.53.0 |
| Multipass | 1.16.4 (installed and tried, not used) |
| MinIO | not used |

## Substitutions

1. MinIO replaced by RustFS. MinIO images were removed from Docker Hub and Quay (pulls failed with "pull access denied" and "unauthorized"). RustFS is S3-compatible on the same ports (9000 and 9001), so the Terraform backend config is unchanged: bucket kijanikiosk-tfstate, endpoint http://localhost:9000. State is kept in a named Docker volume.
2. Multipass replaced by LXD containers. In WSL2, Multipass 1.16.4 instances stayed in the Unknown state with no IP address and the launch timed out even with a 600 second limit. LXD containers get addresses once the firewall rules in lxd-net-fix.sh are applied. That script must be run after each WSL restart and is not part of the Terraform code.

## Known limitation

The state storage has no state locking. Production would use DynamoDB (AWS), built-in GCS locking (GCP) or Consul.

## To reproduce

1. Start RustFS and create the bucket kijanikiosk-tfstate.
2. Run lxd-net-fix.sh.
3. Export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY (set to the RustFS admin login).
4. Run pipeline.sh.
