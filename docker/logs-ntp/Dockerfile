FROM debian:12-slim

RUN apt-get update && apt-get install -y \
    rsyslog \
    chrony \
    && rm -rf /var/lib/apt/lists/*

# Criar diretório de logs remotos
RUN mkdir -p /var/log/remote && \
    chmod 755 /var/log/remote

COPY rsyslog.conf /etc/rsyslog.conf
COPY chrony.conf /etc/chrony/chrony.conf

EXPOSE 514/udp 514/tcp 123/udp

# Script de inicialização
RUN echo '#!/bin/bash\n\
mkdir -p /var/log/remote\n\
rsyslogd -n &\n\
chronyd -d &\n\
wait' > /start.sh && chmod +x /start.sh

CMD ["/start.sh"]
