#!/bin/bash
# Script para permitir autenticação LDAP simples (sem criptografia obrigatória)
# Usado para ambiente de teste - NÃO usar em produção

set -e

DOMAIN_DN="${DOMAIN_DN:-dc=empresa,dc=local}"

echo "Configurando LDAP para permitir autenticação simples..."

# Método 1: Modificar diretamente o banco de dados LDAP
# Desabilitar a exigência de criptografia para simple bind
ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF
dn: CN=Default Domain Policy,CN=System,${DOMAIN_DN}
changetype: modify
replace: dSHeuristics
dSHeuristics: 0000002
-
EOF 2>/dev/null || echo "   Método 1: Não aplicável ou já configurado"

# Método 2: Usar samba-tool para configurar
# Permitir autenticação simples através de configuração de política
samba-tool domain passwordsettings set --min-pwd-age=0 2>/dev/null || true

# Método 3: Modificar configuração do Samba diretamente
# Adicionar configuração no smb.conf se não existir
if [ -f "/etc/samba/smb.conf" ]; then
    if ! grep -q "ldap server require strong auth" /etc/samba/smb.conf; then
        echo "" >> /etc/samba/smb.conf
        echo "# Permitir autenticação simples para ambiente de teste" >> /etc/samba/smb.conf
        echo "ldap server require strong auth = no" >> /etc/samba/smb.conf
    fi
fi

echo "Configuração aplicada!"
echo "IMPORTANTE: Esta configuração reduz a segurança. Use apenas em ambiente de teste!"
