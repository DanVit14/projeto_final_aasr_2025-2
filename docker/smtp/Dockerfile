FROM debian:12-slim

# Instalar dependências
RUN apt-get update && apt-get install -y \
    postfix \
    postfix-ldap \
    dovecot-core \
    dovecot-imapd \
    dovecot-pop3d \
    dovecot-ldap \
    clamav \
    clamav-daemon \
    clamav-freshclam \
    amavisd-new \
    spamassassin \
    mailutils \
    sasl2-bin \
    libsasl2-modules \
    libsasl2-modules-ldap \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Criar diretórios necessários
RUN mkdir -p /var/mail/vhosts/empresa.local \
    /var/spool/postfix/var/lib/sasl2 \
    /etc/postfix/ldap \
    /var/lib/amavis/tmp

# Configurar permissões
RUN chown -R postfix:postfix /var/spool/postfix/var/lib/sasl2 \
    && chmod 755 /var/mail/vhosts

# Atualizar definições de vírus do ClamAV (pode falhar, mas não é crítico)
RUN freshclam || echo "ClamAV definitions will be updated on first run"

# Copiar arquivos de configuração
COPY main.cf /etc/postfix/main.cf
COPY master.cf /etc/postfix/master.cf
COPY ldap/ /etc/postfix/ldap/
COPY dovecot.conf /etc/dovecot/dovecot.conf
COPY dovecot-ldap.conf.ext /etc/dovecot/dovecot-ldap.conf.ext
COPY amavisd.conf /etc/amavis/conf.d/50-user
COPY init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh

EXPOSE 25 587 993 995

CMD ["/usr/local/bin/init.sh"]
