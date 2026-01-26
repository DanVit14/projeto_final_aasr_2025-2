FROM debian:12-slim

# Instalar dependências
RUN apt-get update && apt-get install -y \
    samba \
    samba-common-bin \
    samba-dsdb-modules \
    samba-vfs-modules \
    krb5-user \
    krb5-config \
    ldap-utils \
    winbind \
    acl \
    attr \
    procps \
    net-tools \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Criar diretórios necessários
RUN mkdir -p /var/lib/samba \
    /var/log/samba \
    /etc/samba

# Copiar arquivos de configuração
COPY samba.conf /etc/samba/smb.conf.template
COPY init.sh /usr/local/bin/init.sh
COPY provision.sh /usr/local/bin/provision.sh

RUN chmod +x /usr/local/bin/init.sh /usr/local/bin/provision.sh

EXPOSE 389 636 88 445 135 53

CMD ["/usr/local/bin/init.sh"]
