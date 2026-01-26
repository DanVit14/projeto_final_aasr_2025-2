#!/bin/bash
# Script de inicialização do Samba AD

set -e

echo "=========================================="
echo "Inicializando Samba AD Domain Controller"
echo "=========================================="

# Variáveis de ambiente
DOMAIN="${DOMAIN:-empresa.local}"
ADMIN_PASS="${ADMIN_PASS:-Admin@123}"

# Verificar se já existe domínio configurado
if [ ! -f "/var/lib/samba/private/sam.ldb" ]; then
    echo "Domínio não encontrado. Provisionando..."
    /usr/local/bin/provision.sh
fi

# Copiar configuração do template
if [ ! -f "/etc/samba/smb.conf" ]; then
    echo "Copiando configuração do Samba..."
    cp /etc/samba/smb.conf.template /etc/samba/smb.conf
fi

# Verificar configuração
echo "Verificando configuração do Samba..."
testparm -s > /dev/null

# Iniciar serviços
echo "Iniciando serviços Samba..."
echo ""

# Iniciar Samba em modo foreground para ver logs
exec /usr/sbin/samba -i -F --no-process-group
