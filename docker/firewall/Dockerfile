FROM debian:12-slim

RUN apt-get update && apt-get install -y \
    iptables \
    netfilter-persistent \
    iptables-persistent \
    rsyslog \
    && rm -rf /var/lib/apt/lists/*

COPY iptables.rules /etc/iptables/rules.v4
COPY firewall.sh /usr/local/bin/firewall.sh

RUN chmod +x /usr/local/bin/firewall.sh

EXPOSE 22

CMD ["/usr/local/bin/firewall.sh"]
