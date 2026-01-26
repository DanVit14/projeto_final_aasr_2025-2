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
    # IMPORTANTE: Remover smb.conf se existir (o provisionamento precisa gerar)
    # Não remover smb.conf.template pois está montado como volume read-only
    rm -f /etc/samba/smb.conf
    /usr/local/bin/provision.sh
    # Após provisionamento, adicionar compartilhamentos ao smb.conf gerado
    if [ -f "/etc/samba/smb.conf" ]; then
        echo "" >> /etc/samba/smb.conf
        echo "# Compartilhamentos" >> /etc/samba/smb.conf
        echo "[public]" >> /etc/samba/smb.conf
        echo "    path = /shared/public" >> /etc/samba/smb.conf
        echo "    comment = Compartilhamento Público" >> /etc/samba/smb.conf
        echo "    read only = no" >> /etc/samba/smb.conf
        echo "    browseable = yes" >> /etc/samba/smb.conf
        echo "    guest ok = yes" >> /etc/samba/smb.conf
        echo "    create mask = 0666" >> /etc/samba/smb.conf
        echo "    directory mask = 0777" >> /etc/samba/smb.conf
        echo "" >> /etc/samba/smb.conf
        echo "[private]" >> /etc/samba/smb.conf
        echo "    path = /shared/private" >> /etc/samba/smb.conf
        echo "    comment = Compartilhamento Privado" >> /etc/samba/smb.conf
        echo "    read only = no" >> /etc/samba/smb.conf
        echo "    browseable = yes" >> /etc/samba/smb.conf
        echo "    guest ok = no" >> /etc/samba/smb.conf
        echo "    valid users = @\"EMPRESA\\Users\", @\"EMPRESA\\Admins\"" >> /etc/samba/smb.conf
        echo "    write list = @\"EMPRESA\\Users\", @\"EMPRESA\\Admins\"" >> /etc/samba/smb.conf
        echo "    create mask = 0660" >> /etc/samba/smb.conf
        echo "    directory mask = 0770" >> /etc/samba/smb.conf
    fi
else
    echo "Domínio já existe. Usando configuração existente."
fi

# Verificar configuração
echo "Verificando configuração do Samba..."
testparm -s > /dev/null

# Iniciar serviços
echo "Iniciando serviços Samba..."
echo ""

# Iniciar Samba em modo foreground para ver logs
exec /usr/sbin/samba -i -F --no-process-group
