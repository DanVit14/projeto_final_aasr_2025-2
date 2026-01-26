FROM debian:12-slim

RUN apt-get update && apt-get install -y \
    rsyslog \
    chrony \
    && rm -rf /var/lib/apt/lists/*

COPY rsyslog.conf /etc/rsyslog.conf
COPY chrony.conf /etc/chrony/chrony.conf

EXPOSE 514/udp 514/tcp 123/udp

CMD ["/bin/bash", "-c", "rsyslogd -n & chronyd -d && wait"]
