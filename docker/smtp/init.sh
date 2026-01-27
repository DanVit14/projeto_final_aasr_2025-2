#!/bin/bash
# Script de inicialização do SMTP + Antivírus

set +e  # Não parar em erros

echo "=========================================="
echo "Inicializando SMTP + Antivírus"
echo "=========================================="

# Variáveis de ambiente
DOMAIN="${DOMAIN:-empresa.local}"
LDAP_SERVER="${LDAP_SERVER:-ldap}"
LDAP_BASE="${LDAP_BASE:-dc=empresa,dc=local}"

# Configurar LDAP globalmente para ignorar verificação de certificado
echo "Configurando LDAP globalmente..."
if ! grep -q "TLS_REQCERT" /etc/ldap/ldap.conf 2>/dev/null; then
    echo "TLS_REQCERT never" >> /etc/ldap/ldap.conf
    echo "   ✓ Configuração LDAP global adicionada"
fi

# Extrair e instalar certificado CA do LDAP
echo "Extraindo certificado CA do LDAP..."
LDAP_CA_CERT="/etc/ssl/certs/samba-ca.crt"
# Tentar extrair o certificado CA do servidor LDAP
if timeout 10 openssl s_client -connect ${LDAP_SERVER}:636 -showcerts </dev/null 2>/dev/null | \
   sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' | \
   grep -A 100 "Samba.*CA certificate" | \
   sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > "${LDAP_CA_CERT}" 2>/dev/null; then
    if [ -s "${LDAP_CA_CERT}" ]; then
        echo "   ✓ Certificado CA extraído"
        # Adicionar ao bundle de certificados
        cat "${LDAP_CA_CERT}" >> /etc/ssl/certs/ca-certificates.crt
        update-ca-certificates >/dev/null 2>&1 || true
        echo "   ✓ Certificado CA adicionado ao bundle"
    else
        echo "   ⚠ Certificado CA vazio, tentando método alternativo..."
        # Método alternativo: extrair o segundo certificado (CA) da cadeia
        timeout 10 openssl s_client -connect ${LDAP_SERVER}:636 -showcerts </dev/null 2>/dev/null | \
            sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' | \
            tail -n +$(($(grep -n "BEGIN CERTIFICATE" | tail -1 | cut -d: -f1) + 1)) > "${LDAP_CA_CERT}" 2>/dev/null || true
        if [ -s "${LDAP_CA_CERT}" ]; then
            cat "${LDAP_CA_CERT}" >> /etc/ssl/certs/ca-certificates.crt
            update-ca-certificates >/dev/null 2>&1 || true
            echo "   ✓ Certificado CA adicionado (método alternativo)"
        fi
    fi
else
    echo "   ⚠ Não foi possível extrair certificado CA automaticamente"
    echo "   O Postfix usará tls_require_cert=no (sem verificação de certificado)"
fi

# Aguardar LDAP estar pronto
echo "Aguardando LDAP estar disponível..."
LDAP_READY=0
for i in {1..15}; do
    # Tentar LDAPS primeiro (é o que vamos usar)
    if ldapsearch -x -H ldaps://${LDAP_SERVER}:636 -b "${LDAP_BASE}" -D "cn=Administrator,cn=Users,${LDAP_BASE}" -w "Admin@123" -o nettimeout=5 >/dev/null 2>&1; then
        echo "   ✓ LDAP está disponível (LDAPS)"
        LDAP_READY=1
        break
    fi
    # Tentar LDAP normal com StartTLS (porta 389)
    if ldapsearch -x -H ldap://${LDAP_SERVER}:389 -b "${LDAP_BASE}" -D "cn=Administrator,cn=Users,${LDAP_BASE}" -w "Admin@123" -ZZ -o nettimeout=5 >/dev/null 2>&1; then
        echo "   ✓ LDAP está disponível (LDAP com StartTLS)"
        LDAP_READY=1
        break
    fi
    if [ $i -eq 1 ]; then
        echo "   Aguardando conexão LDAP..."
    fi
    sleep 2
done

if [ $LDAP_READY -eq 0 ]; then
    echo "   ⚠ LDAP não está acessível ainda (continuando mesmo assim)"
    echo "   Os serviços podem funcionar quando o LDAP estiver pronto"
fi

# Criar diretórios necessários
mkdir -p /var/mail/vhosts/${DOMAIN}
mkdir -p /var/lib/amavis/virusmails
mkdir -p /var/lib/amavis/tmp
mkdir -p /var/spool/postfix/var/lib/sasl2
mkdir -p /var/run/dovecot

# Criar diretórios do Postfix queue (necessário para postdrop funcionar)
mkdir -p /var/spool/postfix/public
mkdir -p /var/spool/postfix/maildrop
mkdir -p /var/spool/postfix/incoming
mkdir -p /var/spool/postfix/active
mkdir -p /var/spool/postfix/deferred
mkdir -p /var/spool/postfix/hold
mkdir -p /var/spool/postfix/bounce
mkdir -p /var/spool/postfix/pid

# Configurar permissões
chown -R postfix:postfix /var/mail/vhosts
chown -R postfix:postfix /var/spool/postfix/var/lib/sasl2
chown -R amavis:amavis /var/lib/amavis 2>/dev/null || true
# ClamAV (clamd) precisa de ler ficheiros em /var/lib/amavis/tmp ao varrê-los.
# tmp amavis:amavis 770 + clamav no grupo amavis (ver abaixo) = clamd consegue ler.
chmod 770 /var/lib/amavis/tmp 2>/dev/null || true
chown -R dovecot:dovecot /var/run/dovecot 2>/dev/null || true

# Permissões específicas para Postfix queue
# Diretório principal deve ser root:root
chown root:root /var/spool/postfix
chmod 755 /var/spool/postfix

# public e maildrop devem ser postfix:postdrop com setgid para postdrop funcionar
chown postfix:postdrop /var/spool/postfix/public /var/spool/postfix/maildrop
chmod 2755 /var/spool/postfix/public  # 2755 = rwxr-sr-x (setgid)
chmod 2775 /var/spool/postfix/maildrop  # 2775 = rwxrwsr-x (setgid + group write)

# Outros diretórios de queue devem ser postfix:postfix (pid deve ficar root:root)
chown postfix:postfix /var/spool/postfix/incoming \
    /var/spool/postfix/active \
    /var/spool/postfix/deferred \
    /var/spool/postfix/hold \
    /var/spool/postfix/bounce \
    /var/spool/postfix/private 2>/dev/null || true
chown root:root /var/spool/postfix/pid 2>/dev/null || true
chmod 755 /var/spool/postfix/incoming
chmod 755 /var/spool/postfix/active
chmod 755 /var/spool/postfix/deferred
chmod 755 /var/spool/postfix/hold
chmod 755 /var/spool/postfix/bounce
chmod 700 /var/spool/postfix/private

# Garantir que os arquivos de configuração do Postfix sejam do root
chown root:root /etc/postfix/main.cf /etc/postfix/master.cf 2>/dev/null || true

# --- Postfix primeiro (porta 25 disponível em ~30–60 s); ClamAV/Amavis depois ---
echo "Atualizando maps LDAP e iniciando Postfix..."
mkdir -p /etc/postfix/ldap
chown root:root /etc/postfix/ldap
chmod 755 /etc/postfix/ldap
/usr/sbin/postfix check
sleep 2
if [ -f /usr/local/bin/update-ldap-maps.sh ]; then
    /usr/local/bin/update-ldap-maps.sh 2>&1
fi
for file in virtual-mailbox-domains.hash virtual-mailbox-maps.hash virtual-alias-maps.hash sender-login-maps.hash; do
    [ ! -f "/etc/postfix/ldap/$file" ] && touch "/etc/postfix/ldap/$file"
    [ ! -f "/etc/postfix/ldap/${file}.db" ] && postmap "/etc/postfix/ldap/$file" 2>/dev/null || true
done
/usr/sbin/postfix stop 2>/dev/null || true
sleep 1
POSTFIX_UID=$(id -u postfix 2>/dev/null || echo "106")
POSTFIX_GID=$(id -g postfix 2>/dev/null || echo "114")
[ -n "$POSTFIX_UID" ] && [ -n "$POSTFIX_GID" ] && sed -i "s/^virtual_uid_maps = .*/virtual_uid_maps = static:${POSTFIX_UID}/" /etc/postfix/main.cf 2>/dev/null && sed -i "s/^virtual_gid_maps = .*/virtual_gid_maps = static:${POSTFIX_GID}/" /etc/postfix/main.cf 2>/dev/null || true
if [ -f /etc/rsyslog.d/50-mail.conf ] && command -v rsyslogd >/dev/null 2>&1; then
    touch /var/log/mail.log
    chmod 644 /var/log/mail.log
    rsyslogd 2>/dev/null &
    sleep 1
fi
echo "   Iniciando Postfix (porta 25)..."
/usr/sbin/postfix start
sleep 3
chmod o+x /var/spool/postfix/public 2>/dev/null || true
/usr/sbin/postfix status >/dev/null 2>&1 && echo "   ✓ Postfix a escutar na porta 25"

# --- Serviços auxiliares (ClamAV, Amavis, Dovecot) depois do Postfix ---
echo "Iniciando serviços auxiliares (ClamAV, Amavis, Dovecot)..."
freshclam >/dev/null 2>&1 &
for d in /var/run/clamav /run/clamav; do
    mkdir -p "$d" 2>/dev/null
    chown clamav:clamav "$d" 2>/dev/null || chown clamav:root "$d" 2>/dev/null || true
done
CLAM_DB_DIR="${CLAM_DB_DIR:-/var/lib/clamav}"
if [ -f /etc/clamav/clamd.conf ] && [ ! -e "$CLAM_DB_DIR/main.cvd" ] && [ ! -e "$CLAM_DB_DIR/daily.cvd" ] && [ ! -e "$CLAM_DB_DIR/daily.cld" ]; then
    echo "   Aguardando base ClamAV (máx. 15 s)..."
    for i in $(seq 1 15); do
        [ -e "$CLAM_DB_DIR/main.cvd" ] || [ -e "$CLAM_DB_DIR/daily.cvd" ] || [ -e "$CLAM_DB_DIR/daily.cld" ] && break
        sleep 1
    done
fi
if [ -f /etc/clamav/clamd.conf ]; then
    clamd 2>/tmp/clamd_start.log &
    sleep 2
fi
sa-update >/dev/null 2>&1 &
CLAMD_SOCKET=""
for i in $(seq 1 10); do
    for s in /var/run/clamav/clamd.ctl /run/clamav/clamd.ctl /var/run/clamav/clamd.sock; do
        [ -S "$s" ] 2>/dev/null && CLAMD_SOCKET="$s" && break 2
    done
    sleep 1
done
getent group clamav >/dev/null 2>&1 && getent passwd amavis >/dev/null 2>&1 && usermod -aG clamav amavis 2>/dev/null || true
AMAVISD_BIN=""
for c in /usr/sbin/amavisd /usr/sbin/amavisd-new amavisd amavisd-new; do
    [ -x "$c" ] 2>/dev/null || command -v "$c" >/dev/null 2>&1 && AMAVISD_BIN="$c" && break
done
if [ -n "$AMAVISD_BIN" ] && [ -n "$CLAMD_SOCKET" ] && [ -f /etc/amavis/conf.d/50-user ]; then
    $AMAVISD_BIN start >/dev/null 2>&1 || true
fi
[ -f /etc/dovecot/dovecot.conf ] && dovecot >/dev/null 2>&1 &

echo ""
echo "Postfix iniciado. Mantendo container rodando..."
echo ""

# Manter o container rodando
# Usar um loop para manter o processo vivo e verificar se o Postfix ainda está rodando
while true; do
    # Verificar se o Postfix ainda está rodando a cada 30 segundos
    if ! /usr/sbin/postfix status >/dev/null 2>&1; then
        echo "Postfix parou! Reiniciando..."
        /usr/sbin/postfix start
        sleep 5
    fi
    sleep 30
done
