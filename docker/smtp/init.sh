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

# Aguardar LDAP estar pronto
echo "Aguardando LDAP estar disponível..."
LDAP_READY=0
for i in {1..15}; do
    # Tentar LDAP normal com StartTLS (porta 389)
    if ldapsearch -x -H ldap://${LDAP_SERVER}:389 -b "${LDAP_BASE}" -D "cn=Administrator,cn=Users,${LDAP_BASE}" -w "Admin@123" -ZZ >/dev/null 2>&1; then
        echo "   ✓ LDAP está disponível (LDAP com StartTLS)"
        LDAP_READY=1
        break
    fi
    # Tentar LDAP normal sem StartTLS (pode falhar por autenticação forte, mas testa conectividade)
    if ldapsearch -x -H ldap://${LDAP_SERVER}:389 -b "${LDAP_BASE}" -D "cn=Administrator,cn=Users,${LDAP_BASE}" -w "Admin@123" >/dev/null 2>&1; then
        echo "   ✓ LDAP está acessível (LDAP normal - pode precisar StartTLS)"
        LDAP_READY=1
        break
    fi
    # Tentar LDAPS como último recurso
    if ldapsearch -x -H ldaps://${LDAP_SERVER}:636 -b "${LDAP_BASE}" -D "cn=Administrator,cn=Users,${LDAP_BASE}" -w "Admin@123" >/dev/null 2>&1; then
        echo "   ✓ LDAP está disponível (LDAPS)"
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

# Configurar permissões
chown -R postfix:postfix /var/mail/vhosts
chown -R postfix:postfix /var/spool/postfix/var/lib/sasl2
chown -R amavis:amavis /var/lib/amavis 2>/dev/null || true
chown -R dovecot:dovecot /var/run/dovecot 2>/dev/null || true

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

# Iniciar Postfix
echo "Iniciando Postfix..."

# Verificar configuração antes de iniciar
/usr/sbin/postfix check

# Iniciar Postfix em foreground para manter o container rodando
# e ver os logs em tempo real
exec /usr/sbin/postfix start-fg
