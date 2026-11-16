FROM alpine:3.20

# iproute2: address and route handling after the DHCP lease
# tftp-hpa: TFTP client used to fetch the boot file named in option 67
# udhcpc and wget come from busybox, which is part of the base image.
RUN apk add --no-cache iproute2 tftp-hpa

COPY ztp-client.sh udhcpc-script.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/ztp-client.sh /usr/local/bin/udhcpc-script.sh

ENTRYPOINT ["/usr/local/bin/ztp-client.sh"]
