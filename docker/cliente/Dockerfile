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

# test_services.sh é montado em runtime via docker-compose:
# volumes: - ./scripts/test_services.sh:/usr/local/bin/test_services.sh:ro

CMD ["/bin/bash"]
