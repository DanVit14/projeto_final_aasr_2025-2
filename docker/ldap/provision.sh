#!/bin/bash
# Script para provisionar o domínio Samba AD

set -e

DOMAIN="${DOMAIN:-empresa.local}"
DOMAIN_UP="${DOMAIN^^}"
DOMAIN_DN="dc=$(echo $DOMAIN | sed 's/\./,dc=/g')"
ADMIN_PASS="${ADMIN_PASS:-Admin@123}"

echo "=========================================="
echo "Provisionando Samba AD Domain Controller"
echo "=========================================="
echo "Domínio: $DOMAIN"
echo "DN: $DOMAIN_DN"
echo ""

# Verificar se já foi provisionado
if [ -f "/var/lib/samba/private/sam.ldb" ]; then
    echo "Domínio já foi provisionado. Pulando..."
    exit 0
fi

# Provisionar o domínio
echo "Provisionando domínio Active Directory..."
samba-tool domain provision \
    --realm="$DOMAIN" \
    --domain="${DOMAIN_UP%%.*}" \
    --adminpass="$ADMIN_PASS" \
    --dns-backend=SAMBA_INTERNAL \
    --use-rfc2307 \
    --function-level=2008_R2 \
    --server-role=dc

echo ""
echo "Domínio provisionado com sucesso!"
echo ""
echo "Credenciais padrão:"
echo "  Usuário: Administrator"
echo "  Senha: $ADMIN_PASS"
echo ""

# Criar usuários de exemplo
echo "Criando usuários de exemplo..."

# Criar usuário admin (se não existir)
samba-tool user create admin "Admin@123" --given-name="Admin" --surname="User" 2>/dev/null || true

# Criar usuário user1
samba-tool user create user1 "User1@123" --given-name="Usuario" --surname="Um" 2>/dev/null || true

# Criar usuário user2
samba-tool user create user2 "User2@123" --given-name="Usuario" --surname="Dois" 2>/dev/null || true

# Criar grupos
echo "Criando grupos..."
samba-tool group add "Admins" 2>/dev/null || true
samba-tool group add "Users" 2>/dev/null || true
samba-tool group add "Guests" 2>/dev/null || true

# Adicionar usuários aos grupos
samba-tool group addmembers "Admins" admin 2>/dev/null || true
samba-tool group addmembers "Users" user1,user2 2>/dev/null || true

# Configurar compartilhamentos
echo "Configurando compartilhamentos..."

# Criar diretórios de compartilhamento
mkdir -p /shared/public /shared/private

# Configurar permissões e ACLs
chmod 777 /shared/public
chmod 770 /shared/private

# Configurar ACLs no compartilhamento privado (apenas grupo Users)
setfacl -m g:"${DOMAIN_UP%%.*}\\Users":rwx /shared/private 2>/dev/null || true
setfacl -m g:"${DOMAIN_UP%%.*}\\Admins":rwx /shared/private 2>/dev/null || true

echo ""
echo "Provisionamento concluído!"
echo ""
