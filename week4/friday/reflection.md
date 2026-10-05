# Reflection

## 1. A conflict between requirements

The conflict I hit was the one in Challenge D. Requirement 5 needs kk-payments to score below 2.5, which pushed me to use ProtectSystem=strict. That makes almost the whole system read-only for the service. But Requirement 2 has Ansible writing a config file that the service must read. I put the environment file under /opt/kijanikiosk/config, which the service user can read, instead of /etc. Then I checked it by reading the file as the service user, and it printed correctly. The score came out at 1.2. I learned that the hardening choices and the file layout have to be designed together, not one after the other.

A second conflict was between the Multipass requirement and my laptop. In WSL2 the Multipass machines never got an IP address, so I switched Terraform to LXD containers and documented the reason.

## 2. The same sentence for Nia and for Tendo

For Nia: "Each service runs with a read-only view of the server, so even if an attacker took over one service, they could not change the system itself."

For Tendo: "ProtectSystem=strict mounts the file system hierarchy read-only for the unit, apart from /dev, /proc, /sys and any ReadWritePaths, so a compromised process cannot persist changes outside its allowed paths."

What is lost is the plain picture of what an attacker can and cannot do, and the business meaning of it. What is gained is the exact directive, its scope and its exceptions, which Tendo can search for, test and audit.

## 3. The most fragile handoff

The most fragile handoff is from Terraform to Ansible. When Terraform finishes, the servers exist and have IP addresses, but that does not mean they are ready. My script waits until SSH works, but a working SSH login does not prove that outbound network access and DNS work for package installs. In my setup, freshly built servers sometimes stalled at package installation, and the container network also needed a manual firewall fix on my laptop that is not in the code.

To make it robust I would need to know how addresses are assigned and whether they can change, what outbound access the servers have (proxy, firewall, package mirror), which DNS resolver they use, whether IPv6 is available, and how long first-boot setup takes. Then I would replace the fixed waiting loop with real readiness checks (first-boot setup finished, DNS resolves, package mirror reachable) and fail with a clear message.
