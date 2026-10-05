# Hardening Decisions: KijaniKiosk Staging Environment

*Written for Nia. No technical background needed.*

## What this covers

The staging environment is three servers: one for the public service, one for payments and one for collecting logs. Everything about them is written down as code, kept under version control, and is designed to be rebuilt from scratch with a single script. This document explains the security choices built into that code, what each one protects against and, honestly, what it does not.

## How it is built

Two tools do the work. The first creates the servers and records what exists in shared storage, so the team never depends on one person's memory. The second configures every server the same way each time. When we repeated each step, the second pass changed nothing, which shows the setup is repeatable rather than a one-off. Every change is meant to pass a written review before it reaches the servers, much like a contract change, so the board can see who approved what and when.

## Security controls

Each service runs with a read-only view of the server, so even if an attacker took over one service, they could not change the system itself. The table lists every control, including the decisions made when the servers are created.

| Control | What it does | Risk mitigated |
|---|---|---|
| Firewall on each server | Blocks all incoming connections except remote login and the service's own entry point | Attackers probing for other open doors |
| Key-based remote login | Accepts a registered key pair instead of passwords | Password guessing and stolen passwords |
| Remote state storage | Keeps the record of what exists in shared storage, not on one laptop | Lost or conflicting records, unnoticed changes |
| Dedicated service accounts | Runs each service as its own user that cannot log in | One compromised service reaching the others |
| No privilege escalation (NoNewPrivileges) | Stops a running program from gaining extra permissions | A small foothold turning into full control |
| Read-only system (ProtectSystem=strict) | Lets the service see the system but not change it | Tampering with system files |
| Private temporary space (PrivateTmp) | Gives the service its own scratch area | Spying on or interfering with other programs' temporary data |
| Hidden home folders and devices (ProtectHome, PrivateDevices) | Blocks access to user files and hardware | Theft of personal data and hardware misuse |
| Restricted system requests (SystemCallFilter) | Allows only the ordinary requests a service needs | Attacks that rely on unusual operations |
| Removed special powers (CapabilityBoundingSet) | Strips administrator-style abilities | Misuse of powers the service never needed |
| Persistent, rotated logs | Keeps logs across restarts and deletes old ones automatically | Lost evidence after a restart, disks filling up |
| Configuration as code | Writes every setting down and reviews it before use | Undocumented manual changes and drift |

## Decisions worth knowing about

We gave each service its own account and its own tight limits instead of one shared setup. This costs extra configuration work but keeps any damage contained. We also made the firewall refuse everything by default and open only what is needed, which means a new service needs a deliberate firewall change before it works. Finally, each service's settings sit where the running service can read them but cannot rewrite them, so a hijacked service cannot quietly change its own rules.

## The payments score

Payments is the most sensitive service because it handles money. The server's built-in scoring tool rates how exposed a service is, where 0 is fully locked down and 10 is wide open. Payments scores 1.2, well under our target of 2.5. In practice, the service runs with almost none of the abilities an attacker would want.

## Known limitation: shared records

The storage holding our infrastructure records cannot lock them while someone is making changes. If two engineers made changes at the same moment, they could overwrite each other's work. That is acceptable for a one-person staging setup. Production systems solve it with a locking service: a dedicated database table on Amazon, locking built into Google's storage, or a vendor-neutral tool called Consul.

## Substitutions we made

Two planned tools were replaced. The recommended storage product stopped publishing installable packages, so we used a compatible alternative. The virtual machine tool would not hand out network addresses on our development laptop, so we used lightweight containers. They behave like servers for our purposes but share the host computer's core, which is a weaker boundary than full virtual machines.

## What this setup does not protect against

This setup lowers risk but does not make staging safe against a determined attacker. There is no monitoring or alerting, so a break-in could go unnoticed. The storage uses default administrator credentials and unencrypted connections, which is tolerable on one laptop and unacceptable anywhere shared. There is no secrets vault, so any real passwords added later would sit in plain configuration. One key opens all three servers, and access is allowed from the whole internal network rather than approved addresses only. Containers share the host computer's core, so a flaw there affects all three servers. We have not defined an update schedule, nothing is backed up, and each service currently runs a placeholder program rather than the real application. These gaps must be closed before production.
