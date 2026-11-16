# zerotouch-net

Zero-touch provisioning (ZTP) for campus and lab networks, built and demonstrated entirely as a simulation.

A new device that joins the network is discovered through DHCP, identified from its MAC address or DHCP vendor class, and configured according to its role (switch, access point or router) without manual intervention. Configuration and inventory are stored in Git, which acts as the single source of truth.

This project was developed as part of an application to the Taiwan Experience Education Program (TEEP).

## Status

| Stage | Scope | Status |
|-------|-------|--------|
| 1 | DHCP (options 66/67), TFTP and HTTP servers, simulated devices | In progress |
| 2 | Inventory and role identification (MAC, option 60) | Planned |
| 3 | Jinja2 templates per role, delivered with Ansible | Planned |
| 4 | Git as source of truth (branching, last known good tag, secrets) | Planned |
| 5 | Configuration drift detection and automatic rollback | Planned |
| 6 | Continuous integration (template validation, ansible-lint, tests) | Planned |
| 7 | Documentation, architecture diagram, demo script | Planned |

Optional AI features (device role classification from DHCP fingerprints, drift anomaly detection) will only be started after stages 1 to 7 are complete.

## Scope and limitations

- The project runs on Docker Compose. No physical network equipment is used.
- A simulated device is a Linux container with a DHCP client, a TFTP client and a configuration file that stands in for a running configuration. It is not a network operating system.
- TFTP is unauthenticated by design. The simulation is intended to run on an isolated bridge network only. Secrets will be handled with Ansible Vault in later stages.

## Repository layout

```text
docker/            Container images (DHCP/TFTP, HTTP, device simulator, controller)
inventory/         Device inventory: MAC address or vendor class to role
ansible/           Playbooks and roles
templates/         Jinja2 configuration templates per role
scripts/           Helper scripts (drift detection, rollback)
tests/             Unit and integration tests
docs/              Architecture notes, decision records, report notes
```

Directories are added or filled as each stage is completed.

## Prerequisites

- Docker Desktop (WSL2 backend on Windows) or Docker Engine, with Docker Compose v2
- Git

Ansible is run from a container in later stages, so it does not need to be installed on the host.

## License

Released under the MIT License. See [LICENSE](LICENSE).
