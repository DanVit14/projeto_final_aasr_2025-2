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
    ldap-utils \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Criar diretórios necessários
RUN mkdir -p /var/mail/vhosts/empresa.local \
    /var/spool/postfix/var/lib/sasl2 \
    /var/spool/postfix/public \
    /var/spool/postfix/maildrop \
    /var/spool/postfix/incoming \
    /var/spool/postfix/active \
    /var/spool/postfix/deferred \
    /var/spool/postfix/hold \
    /var/spool/postfix/bounce \
    /var/spool/postfix/pid \
    /etc/postfix/ldap \
    /var/lib/amavis/tmp

# Configurar permissões
# Diretório principal deve ser root:root
RUN chown root:root /var/spool/postfix \
    && chmod 755 /var/mail/vhosts \
    && chmod 755 /var/spool/postfix \
    # public e maildrop devem ser postfix:postdrop com setgid para postdrop funcionar
    && chown postfix:postdrop /var/spool/postfix/public /var/spool/postfix/maildrop \
    && chmod 2755 /var/spool/postfix/public \
    && chmod 2775 /var/spool/postfix/maildrop \
    # Outros diretórios de queue devem ser postfix:postfix
    && chown postfix:postfix /var/spool/postfix/incoming /var/spool/postfix/active \
       /var/spool/postfix/deferred /var/spool/postfix/hold \
       /var/spool/postfix/bounce /var/spool/postfix/pid \
    && chmod 755 /var/spool/postfix/incoming /var/spool/postfix/active \
       /var/spool/postfix/deferred /var/spool/postfix/hold \
       /var/spool/postfix/bounce /var/spool/postfix/pid

# Atualizar definições de vírus do ClamAV (pode falhar, mas não é crítico)
RUN freshclam || echo "ClamAV definitions will be updated on first run"

# Configurar LDAP globalmente para ignorar verificação de certificado
RUN echo "TLS_REQCERT never" >> /etc/ldap/ldap.conf

# Copiar arquivos de configuração
COPY main.cf /etc/postfix/main.cf
COPY master.cf /etc/postfix/master.cf
COPY ldap/ /etc/postfix/ldap/
COPY dovecot.conf /etc/dovecot/dovecot.conf
COPY dovecot-ldap.conf.ext /etc/dovecot/dovecot-ldap.conf.ext
COPY amavisd.conf /etc/amavis/conf.d/50-user
COPY init.sh /usr/local/bin/init.sh

# Configurar propriedade dos arquivos do Postfix
RUN chmod +x /usr/local/bin/init.sh \
    && chown root:root /etc/postfix/main.cf /etc/postfix/master.cf \
    && chmod 644 /etc/postfix/main.cf /etc/postfix/master.cf

EXPOSE 25 587 993 995

CMD ["/usr/local/bin/init.sh"]
