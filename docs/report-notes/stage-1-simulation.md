# Stage 1: DHCP, TFTP and HTTP simulation

## Goal

A simulated new device obtains an address through DHCP, learns the TFTP server (option 66) and boot file (option 67), downloads the boot file over TFTP, runs it, and reaches the HTTP provisioning server.

## Components

| Service | Image | Address | Role |
|---------|-------|---------|------|
| dhcp-tftp | alpine + dnsmasq | 172.28.10.2 | DHCP server and TFTP server |
| http | nginx:1.27-alpine | 172.28.10.3 | HTTP provisioning server |
| device-01, device-02 | alpine + udhcpc + tftp-hpa | DHCP (172.28.10.100-200) | Simulated new devices |

Addressing plan for `zt-net` (172.28.10.0/24):

| Range | Use |
|-------|-----|
| 172.28.10.1 | Docker bridge gateway |
| 172.28.10.2 - .4 | Static infrastructure addresses |
| 172.28.10.16/28 | Docker IPAM range (any container started without a static address) |
| 172.28.10.100 - .200 | DHCP pool served by dnsmasq |

The Docker IPAM range is kept apart from the DHCP pool. Otherwise Docker would assign an address to a device before it asks for one, and the DHCP exchange would not be a real test.

## Implementation notes

- Option 66 and 67 values are quoted in `dnsmasq.conf` so that dnsmasq encodes them as strings.
- The device requests both options explicitly (`udhcpc -O tftp -O bootfile`). A server normally only sends options that the client listed in its parameter request list.
- The TFTP client runs in binary mode. The default netascii mode rewrites line endings and corrupts shell scripts.
- `.gitattributes` forces LF line endings. Without it, Git on Windows can check scripts out with CRLF, and they fail inside Linux containers.
- The device replaces the address assigned by Docker with the leased address. This needs the `NET_ADMIN` capability.

## Verification procedure

1. Validate the Compose file:

   ```sh
   docker compose config --quiet
   ```

   Expected: no output and exit code 0.

2. Start the servers:

   ```sh
   docker compose up -d --build
   docker compose ps
   ```

   Expected: `zt-dhcp-tftp` and `zt-http` are running and report `healthy`.

3. Start a simulated device:

   ```sh
   docker compose --profile devices up -d --build device-01
   docker compose logs device-01
   ```

   Expected in the device log: a lease in the range 172.28.10.100-200, TFTP server 172.28.10.2, boot file `bootstrap.sh`, a successful download, and the lines `[bootstrap] HTTP server replied: zerotouch-net provisioning server ready` and `[bootstrap] stage 1 boot chain complete`.

4. Check the server side:

   ```sh
   docker compose logs dhcp-tftp
   ```

   Expected: `DHCPDISCOVER`, `DHCPOFFER`, `DHCPREQUEST` and `DHCPACK` entries for MAC `02:00:00:00:00:01`, the vendor class `zt-sim-switch`, options 66 and 67 in the sent options, and a TFTP entry for `bootstrap.sh`.

5. Repeat with `device-02` (MAC `02:00:00:00:00:02`, vendor class `zt-sim-ap`) and confirm it receives a different address.

## Observed results

To be recorded after the procedure above has been run on the development machine. Paste the relevant log excerpts here.

## Known limitations

- The boot file is the same for every device. Per-device selection is implemented in stage 2.
- TFTP has no authentication or integrity check. This is acceptable only on an isolated simulation network.
