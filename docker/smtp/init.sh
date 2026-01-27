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
chown -R dovecot:dovecot /var/run/dovecot 2>/dev/null || true

# Permissões específicas para Postfix queue
# Diretório principal deve ser root:root
chown root:root /var/spool/postfix
chmod 755 /var/spool/postfix

# public e maildrop devem ser postfix:postdrop com setgid para postdrop funcionar
chown postfix:postdrop /var/spool/postfix/public /var/spool/postfix/maildrop
chmod 2755 /var/spool/postfix/public  # 2755 = rwxr-sr-x (setgid)
chmod 2775 /var/spool/postfix/maildrop  # 2775 = rwxrwsr-x (setgid + group write)

# Outros diretórios de queue devem ser postfix:postfix
chown postfix:postfix /var/spool/postfix/incoming \
    /var/spool/postfix/active \
    /var/spool/postfix/deferred \
    /var/spool/postfix/hold \
    /var/spool/postfix/bounce \
    /var/spool/postfix/pid \
    /var/spool/postfix/private 2>/dev/null || true
chmod 755 /var/spool/postfix/incoming
chmod 755 /var/spool/postfix/active
chmod 755 /var/spool/postfix/deferred
chmod 755 /var/spool/postfix/hold
chmod 755 /var/spool/postfix/bounce
chmod 700 /var/spool/postfix/private

# Garantir que os arquivos de configuração do Postfix sejam do root
chown root:root /etc/postfix/main.cf /etc/postfix/master.cf 2>/dev/null || true

# Atualizar definições de vírus do ClamAV (em background)
echo "Atualizando definições de vírus do ClamAV..."
freshclam >/dev/null 2>&1 &

# Iniciar serviços em background
echo "Iniciando serviços auxiliares..."

# ClamAV daemon (em background)
if [ -f /etc/clamav/clamd.conf ]; then
    clamd >/dev/null 2>&1 &
    echo "   ✓ ClamAV iniciado"
fi

# SpamAssassin (atualizar regras em background)
sa-update >/dev/null 2>&1 &
echo "   ✓ SpamAssassin configurado"

# Amavis (em background) - comentar temporariamente se estiver causando problemas
# if [ -f /etc/amavis/conf.d/50-user ]; then
#     amavisd-new start >/dev/null 2>&1 || echo "   ⚠ Amavis pode precisar de configuração adicional"
# fi
echo "   ⚠ Amavis desabilitado temporariamente para debug"

# Dovecot (em background)
if [ -f /etc/dovecot/dovecot.conf ]; then
    dovecot >/dev/null 2>&1 &
    echo "   ✓ Dovecot iniciado"
fi

# Aguardar um pouco para serviços iniciarem
sleep 5

# Verificar configuração do Postfix
echo "Verificando configuração do Postfix..."
postfix check

if [ $? -eq 0 ]; then
    echo "   ✓ Configuração do Postfix OK"
else
    echo "   ⚠ Avisos na configuração do Postfix (verificar logs)"
fi

# Atualizar arquivos hash do LDAP antes de iniciar Postfix
echo "Atualizando arquivos hash do LDAP..."
if [ -f /usr/local/bin/update-ldap-maps.sh ]; then
    /usr/local/bin/update-ldap-maps.sh
    echo "   ✓ Arquivos hash atualizados"
else
    echo "   ⚠ Script de atualização não encontrado, criando arquivos vazios..."
    touch /etc/postfix/ldap/virtual-mailbox-domains.hash
    touch /etc/postfix/ldap/virtual-mailbox-maps.hash
    touch /etc/postfix/ldap/virtual-alias-maps.hash
    touch /etc/postfix/ldap/sender-login-maps.hash
    postmap /etc/postfix/ldap/virtual-mailbox-domains.hash 2>/dev/null || true
    postmap /etc/postfix/ldap/virtual-mailbox-maps.hash 2>/dev/null || true
    postmap /etc/postfix/ldap/virtual-alias-maps.hash 2>/dev/null || true
    postmap /etc/postfix/ldap/sender-login-maps.hash 2>/dev/null || true
fi

# Iniciar Postfix
echo "Iniciando Postfix..."

# Verificar configuração antes de iniciar
/usr/sbin/postfix check

# Parar Postfix se já estiver rodando (limpeza)
/usr/sbin/postfix stop 2>/dev/null || true
sleep 1

# Garantir que TODOS os diretórios de queue existem antes de iniciar
echo "   Criando diretórios de queue do Postfix..."
mkdir -p /var/spool/postfix/public \
    /var/spool/postfix/maildrop \
    /var/spool/postfix/incoming \
    /var/spool/postfix/active \
    /var/spool/postfix/deferred \
    /var/spool/postfix/hold \
    /var/spool/postfix/bounce \
    /var/spool/postfix/pid \
    /var/spool/postfix/private \
    /var/spool/postfix/var/lib/sasl2

# Configurar propriedade e permissões corretas
# Diretório principal deve ser root:root
chown root:root /var/spool/postfix
chmod 755 /var/spool/postfix

# public e maildrop devem ser postfix:postdrop com setgid para postdrop funcionar
chown postfix:postdrop /var/spool/postfix/public /var/spool/postfix/maildrop
chmod 2755 /var/spool/postfix/public  # 2755 = rwxr-sr-x (setgid)
chmod 2775 /var/spool/postfix/maildrop  # 2775 = rwxrwsr-x (setgid + group write)

# Outros diretórios de queue devem ser postfix:postfix
chown postfix:postfix /var/spool/postfix/incoming \
    /var/spool/postfix/active \
    /var/spool/postfix/deferred \
    /var/spool/postfix/hold \
    /var/spool/postfix/bounce \
    /var/spool/postfix/pid \
    /var/spool/postfix/private 2>/dev/null || true

chmod 755 /var/spool/postfix/incoming
chmod 755 /var/spool/postfix/active
chmod 755 /var/spool/postfix/deferred
chmod 755 /var/spool/postfix/hold
chmod 755 /var/spool/postfix/bounce
chmod 700 /var/spool/postfix/private

# Iniciar Postfix
echo "   Executando: postfix start"
/usr/sbin/postfix start

# Aguardar um pouco para o Postfix iniciar completamente
sleep 5

# Verificar se o Postfix iniciou corretamente
echo "   Verificando status..."
if /usr/sbin/postfix status >/dev/null 2>&1; then
    echo "   ✓ Postfix está rodando"
    
    # Verificar se o smtpd está rodando
    if pgrep -f "smtpd.*smtp" >/dev/null; then
        echo "   ✓ smtpd está rodando"
    else
        echo "   ⚠ smtpd não está rodando - tentando reload"
        /usr/sbin/postfix reload
        sleep 3
        if pgrep -f "smtpd.*smtp" >/dev/null; then
            echo "   ✓ smtpd iniciado após reload"
        else
            echo "   ✗ smtpd ainda não está rodando"
        fi
    fi
else
    echo "   ✗ Postfix não iniciou - tentando novamente..."
    /usr/sbin/postfix start
    sleep 3
    /usr/sbin/postfix status 2>&1 | head -3
fi

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
