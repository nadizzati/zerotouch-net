#!/bin/sh
# Boot file served over TFTP (DHCP option 67).
#
# Stage 1 only proves the boot chain: the device obtained a lease, fetched this
# file over TFTP, and can reach the HTTP provisioning server. Role detection
# and configuration delivery are added in later stages.

set -eu

HTTP_BASE="${ZTP_HTTP_BASE:-http://172.28.10.3}"
STATE_DIR="${STATE_DIR:-/var/lib/ztp}"
IFACE="${IFACE:-eth0}"

echo "[bootstrap] host $(hostname), MAC $(cat "/sys/class/net/$IFACE/address")"
echo "[bootstrap] contacting HTTP provisioning server at $HTTP_BASE"

wget -q -T 10 -O "$STATE_DIR/ztp-ready.txt" "$HTTP_BASE/ztp-ready.txt"

echo "[bootstrap] HTTP server replied: $(cat "$STATE_DIR/ztp-ready.txt")"
echo "[bootstrap] stage 1 boot chain complete"
