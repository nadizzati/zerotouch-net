#!/bin/sh
# udhcpc event handler.
# udhcpc calls this script with the event name in $1 and the lease data in
# environment variables (interface, ip, mask, router, tftp, bootfile, siaddr).
# On a bound lease it configures the interface and records the boot options
# in KEY=VALUE form for ztp-client.sh.

# shellcheck disable=SC2154  # lease variables are exported by udhcpc
LEASE_FILE="${ZTP_LEASE_FILE:-/run/ztp-lease.env}"

case "$1" in
    deconfig)
        ip link set dev "$interface" up
        ;;
    bound|renew)
        # Replace the address that Docker assigned with the one from DHCP.
        ip -4 addr flush dev "$interface"
        ip addr add "$ip/${mask:-24}" dev "$interface"
        if [ -n "${router:-}" ]; then
            ip route replace default via "${router%% *}" dev "$interface"
        fi
        {
            printf 'LEASE_IP=%s\n' "$ip"
            printf 'LEASE_SERVER_ID=%s\n' "${serverid:-}"
            printf 'LEASE_TFTP=%s\n' "${tftp:-}"
            printf 'LEASE_BOOTFILE=%s\n' "${bootfile:-}"
            printf 'LEASE_SIADDR=%s\n' "${siaddr:-}"
        } > "$LEASE_FILE"
        ;;
esac

exit 0
