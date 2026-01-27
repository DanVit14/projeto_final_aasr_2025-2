FROM debian:12-slim

RUN apt-get update && apt-get install -y \
    iptables \
    netfilter-persistent \
    iptables-persistent \
    rsyslog \
    && rm -rf /var/lib/apt/lists/*

COPY iptables.rules /etc/iptables/rules.v4
COPY firewall.sh /usr/local/bin/firewall.sh
COPY rsyslog-forward.conf /etc/rsyslog.d/99-forward.conf

RUN chmod 755 /usr/local/bin/firewall.sh

EXPOSE 22

CMD ["/bin/bash", "/usr/local/bin/firewall.sh"]
