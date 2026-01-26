#!/bin/bash
# Script de inicialização do Samba AD

set -e

echo "Inicializando Samba AD..."

# Verificar se já existe domínio configurado
if [ ! -d "/var/lib/samba/private" ]; then
    echo "Configurando novo domínio..."
    # Comandos de configuração inicial do Samba AD
    # Será implementado conforme necessário
fi

# Iniciar serviços
exec /usr/sbin/samba -i
