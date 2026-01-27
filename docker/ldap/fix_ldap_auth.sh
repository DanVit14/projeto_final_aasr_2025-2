#!/bin/bash
# Script para permitir autenticação LDAP simples (sem criptografia obrigatória)
# Usado para ambiente de teste - NÃO usar em produção

set +e  # Não parar em erros

DOMAIN_DN="${DOMAIN_DN:-dc=empresa,dc=local}"

echo "Configurando LDAP para permitir autenticação simples..."

# Verificar se o domínio já foi provisionado
if [ ! -f "/var/lib/samba/private/sam.ldb" ]; then
    echo "   Domínio ainda não provisionado. Pulando configuração..."
    exit 0
fi

# Método mais confiável: Modificar a política de segurança do domínio
# Isso permite simple bind sem criptografia obrigatória
echo "   Aplicando configuração de segurança..."

# Verificar se já está configurado
CURRENT_HEURISTICS=$(ldbsearch -H /var/lib/samba/private/sam.ldb -b "CN=Default Domain Policy,CN=System,${DOMAIN_DN}" dSHeuristics 2>/dev/null | grep "^dSHeuristics:" | awk '{print $2}')

if [ "$CURRENT_HEURISTICS" != "0000002" ]; then
    # Modificar a política de domínio para permitir simple bind
    ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF 2>/dev/null
dn: CN=Default Domain Policy,CN=System,${DOMAIN_DN}
changetype: modify
replace: dSHeuristics
dSHeuristics: 0000002
-
EOF
    
    if [ $? -eq 0 ]; then
        echo "   ✓ Política de segurança modificada com sucesso"
    else
        echo "   ⚠ Não foi possível modificar a política (pode já estar configurado)"
    fi
else
    echo "   ✓ Política já está configurada corretamente"
fi

# Adicionar configuração no smb.conf se existir
if [ -f "/etc/samba/smb.conf" ]; then
    if ! grep -q "ldap server require strong auth" /etc/samba/smb.conf; then
        echo "" >> /etc/samba/smb.conf
        echo "# Permitir autenticação simples para ambiente de teste" >> /etc/samba/smb.conf
        echo "ldap server require strong auth = no" >> /etc/samba/smb.conf
        echo "   Configuração adicionada ao smb.conf"
    else
        echo "   Configuração já existe no smb.conf"
    fi
fi

echo "Configuração aplicada!"
echo "IMPORTANTE: Esta configuração reduz a segurança. Use apenas em ambiente de teste!"
echo "   Pode ser necessário reiniciar o Samba para aplicar as mudanças."
