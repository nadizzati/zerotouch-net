FROM alpine:3.20

RUN apk add --no-cache dnsmasq \
    && mkdir -p /var/lib/misc /srv/tftp

# Configuration and TFTP root are bind-mounted by docker-compose.yml.
EXPOSE 67/udp 69/udp

ENTRYPOINT ["dnsmasq", "--conf-file=/etc/dnsmasq.conf"]
