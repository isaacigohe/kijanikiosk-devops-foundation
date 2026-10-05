#cloud-config
ssh_authorized_keys:
  - ${ssh_key}
write_files:
  - path: /etc/systemd/resolved.conf.d/dns.conf
    content: |
      [Resolve]
      DNS=8.8.8.8 1.1.1.1
runcmd:
  - systemctl restart systemd-resolved
