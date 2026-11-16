# 001. Use dnsmasq for DHCP and TFTP

Status: accepted

## Context

The simulation needs a DHCP server that can send options 66 and 67 and tag clients by MAC address or vendor class (option 60), plus a TFTP server for the boot file.

## Options considered

| Criterion | dnsmasq | ISC DHCP | Kea |
|-----------|---------|----------|-----|
| DHCP and TFTP in one process | Yes | No, TFTP is separate | No |
| Tagging by MAC or vendor class | Short configuration directives | Supported, more verbose | Supported, JSON configuration |
| Maintenance status | Active | End of life since 2022 | Active |
| Learning curve | Low | Medium | High |

## Decision

Use dnsmasq. It serves both DHCP and TFTP from one small container and its tagging directives map directly onto the inventory model planned for stage 2.

## Consequences

- dnsmasq does not serve HTTP, so a separate nginx container is used for the HTTP side.
- ISC DHCP is not used because it no longer receives updates.
- Kea is the more suitable choice for a production deployment and is noted as future work.
