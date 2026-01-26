FROM debian:12-slim

RUN apt-get update && apt-get install -y \
    postfix \
    postfix-ldap \
    dovecot-core \
    dovecot-imapd \
    dovecot-pop3d \
    clamav \
    clamav-daemon \
    amavisd-new \
    spamassassin \
    && rm -rf /var/lib/apt/lists/*

# Atualizar definições de vírus do ClamAV
RUN freshclam || true

COPY main.cf /etc/postfix/main.cf
COPY master.cf /etc/postfix/master.cf

EXPOSE 25 587 993 995

CMD ["/usr/sbin/postfix", "start-fg"]
