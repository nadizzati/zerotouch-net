# zerotouch-net

Zero-touch provisioning (ZTP) for campus and lab networks, built and demonstrated entirely as a simulation.

A new device that joins the network is discovered through DHCP, identified from its MAC address or DHCP vendor class, and configured according to its role (switch, access point or router) without manual intervention. Configuration and inventory are stored in Git, which acts as the single source of truth.

This project was developed as part of an application to the Taiwan Experience Education Program (TEEP).

## Status

| Stage | Scope | Status |
|-------|-------|--------|
| 1 | DHCP (options 66/67), TFTP and HTTP servers, simulated devices | Implemented, verification in progress |
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

## Architecture (stage 1)

```text
                 zt-net  172.28.10.0/24
  +--------------+  +--------------+  +------------------+
  | dhcp-tftp    |  | http         |  | device-01/02     |
  | dnsmasq      |  | nginx        |  | DHCP + TFTP      |
  | 172.28.10.2  |  | 172.28.10.3  |  | client           |
  +--------------+  +--------------+  +------------------+
```

Boot sequence of a simulated device:

1. The device sends a DHCP discover with its vendor class (option 60) and requests options 66 and 67.
2. dnsmasq replies with an address from the pool 172.28.10.100-200, the TFTP server (option 66) and the boot file name (option 67).
3. The device downloads the boot file over TFTP and runs it.
4. The boot file contacts the HTTP server to confirm that the provisioning service is reachable.

A fuller architecture description will be added to `docs/architecture.md` in stage 7.

## Repository layout

```text
docker/            Container images (DHCP/TFTP, HTTP, device simulator, controller)
provisioning/      Files served to devices (tftp/ and http/)
inventory/         Device inventory: MAC address or vendor class to role
ansible/           Playbooks and roles
templates/         Jinja2 configuration templates per role
scripts/           Helper scripts (drift detection, rollback)
tests/             Unit and integration tests
docs/              Architecture notes, decision records, report notes
.github/workflows/ Continuous integration
```

Some directories are empty until the stage that fills them.

## Prerequisites

- Docker Desktop (WSL2 backend on Windows) or Docker Engine, with Docker Compose v2
- Git

Ansible is run from a container in later stages, so it does not need to be installed on the host.

## Quick start (stage 1)

Start the DHCP/TFTP and HTTP servers:

```sh
docker compose up -d --build
```

Start the simulated devices:

```sh
docker compose --profile devices up -d --build
```

Inspect the result:

```sh
docker compose logs dhcp-tftp
docker compose logs device-01 device-02
```

Stop and remove everything:

```sh
docker compose --profile devices down
```

Detailed steps and verification notes are in [docs/report-notes/stage-1-simulation.md](docs/report-notes/stage-1-simulation.md).

## Design decisions

Decision records are kept in [docs/decisions/](docs/decisions/).

## License

Released under the MIT License. See [LICENSE](LICENSE).
