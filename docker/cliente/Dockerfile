FROM debian:12-slim

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    netcat-openbsd \
    ldap-utils \
    postgresql-client \
    samba-client \
    mailutils \
    chrony \
    && rm -rf /var/lib/apt/lists/*

COPY test_services.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/test_services.sh

CMD ["/bin/bash"]
