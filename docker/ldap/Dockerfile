FROM debian:12-slim

RUN apt-get update && apt-get install -y \
    samba \
    samba-common-bin \
    krb5-user \
    ldap-utils \
    && rm -rf /var/lib/apt/lists/*

COPY samba.conf /etc/samba/smb.conf
COPY init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh

EXPOSE 389 636 88 445 135

CMD ["/usr/local/bin/init.sh"]
