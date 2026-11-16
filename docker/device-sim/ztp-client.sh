#!/bin/sh
# Simulated new device.
#
# Boot sequence:
#   1. Request a DHCP lease, advertising a vendor class (option 60) and
#      asking for the TFTP server (option 66) and boot file (option 67).
#   2. Download the boot file over TFTP.
#   3. Execute the boot file.
#
# Executing a file received over an unauthenticated protocol is acceptable
# only because this is an isolated simulation. See docs/ for the security notes.

set -eu

IFACE="${IFACE:-eth0}"
VENDOR_CLASS="${VENDOR_CLASS:-zt-sim}"
DEVICE_HOSTNAME="${DEVICE_HOSTNAME:-$(hostname)}"
STATE_DIR="${STATE_DIR:-/var/lib/ztp}"
LEASE_FILE="${ZTP_LEASE_FILE:-/run/ztp-lease.env}"
export STATE_DIR ZTP_LEASE_FILE="$LEASE_FILE"

log() {
    printf '[device %s] %s\n' "$DEVICE_HOSTNAME" "$*"
}

# Read one KEY=VALUE entry from the lease file without sourcing it, so that
# a malformed DHCP option can never be executed as shell code.
lease_value() {
    sed -n "s/^$1=//p" "$LEASE_FILE" | head -n 1
}

mkdir -p "$STATE_DIR"
rm -f "$LEASE_FILE"

log "interface $IFACE, MAC $(cat "/sys/class/net/$IFACE/address"), vendor class '$VENDOR_CLASS'"
log "requesting DHCP lease"

# -n: fail if no lease is obtained, -q: exit once the lease is bound.
# -O tftp / -O bootfile: ask the server for options 66 and 67.
# -V: set the vendor class identifier (option 60).
if ! udhcpc -i "$IFACE" -n -q -t 5 -T 3 \
        -s /usr/local/bin/udhcpc-script.sh \
        -V "$VENDOR_CLASS" \
        -x "hostname:$DEVICE_HOSTNAME" \
        -O tftp -O bootfile; then
    log "no DHCP lease obtained, giving up"
    exit 1
fi

LEASE_IP="$(lease_value LEASE_IP)"
TFTP_SERVER="$(lease_value LEASE_TFTP)"
BOOTFILE="$(lease_value LEASE_BOOTFILE)"

# Fall back to the next-server field (siaddr) when option 66 is absent.
if [ -z "$TFTP_SERVER" ]; then
    TFTP_SERVER="$(lease_value LEASE_SIADDR)"
fi

if [ -z "$TFTP_SERVER" ] || [ -z "$BOOTFILE" ]; then
    log "lease has no TFTP server or boot file (option 66/67 missing), giving up"
    exit 1
fi

log "lease bound: address $LEASE_IP, TFTP server $TFTP_SERVER (option 66), boot file $BOOTFILE (option 67)"

# Binary mode is required: the default netascii mode would rewrite line endings.
log "downloading $BOOTFILE over TFTP"
rm -f "$STATE_DIR/bootstrap.sh"
timeout 30 tftp -m binary "$TFTP_SERVER" -c get "$BOOTFILE" "$STATE_DIR/bootstrap.sh" || true

if [ ! -s "$STATE_DIR/bootstrap.sh" ]; then
    log "TFTP download failed or returned an empty file"
    exit 1
fi
log "download complete ($(wc -c < "$STATE_DIR/bootstrap.sh") bytes)"

log "running boot file"
sh "$STATE_DIR/bootstrap.sh"

log "boot sequence finished, device is idle"
exec tail -f /dev/null
