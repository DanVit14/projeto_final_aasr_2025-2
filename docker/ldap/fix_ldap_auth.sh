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

# Método 1: Modificar dSHeuristics na política de domínio
# O valor 0000002 permite simple bind sem criptografia
POLICY_DN="CN=Default Domain Policy,CN=System,${DOMAIN_DN}"

# Verificar se a política existe
if ldbsearch -H /var/lib/samba/private/sam.ldb -b "$POLICY_DN" dn 2>/dev/null | grep -q "^dn:"; then
    # Modificar a política
    ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF 2>/dev/null
dn: $POLICY_DN
changetype: modify
replace: dSHeuristics
dSHeuristics: 0000002
-
EOF
    
    if [ $? -eq 0 ]; then
        echo "   ✓ Política de segurança modificada (dSHeuristics=0000002)"
    else
        # Tentar adicionar se não existir
        ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF 2>/dev/null
dn: $POLICY_DN
changetype: modify
add: dSHeuristics
dSHeuristics: 0000002
-
EOF
        if [ $? -eq 0 ]; then
            echo "   ✓ Política de segurança adicionada (dSHeuristics=0000002)"
        else
            echo "   ⚠ Não foi possível modificar a política diretamente"
        fi
    fi
else
    echo "   ⚠ Política de domínio não encontrada, tentando método alternativo..."
fi

# Método 2: Modificar configuração do LDAP server diretamente
# Adicionar configuração que permite simple bind
if [ -f "/var/lib/samba/private/sam.ldb" ]; then
    # Tentar modificar configuração do LDAP server
    ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF 2>/dev/null
dn: @MODULES
changetype: modify
add: @LIST
@LIST: simple_bind
-
EOF
    echo "   Tentativa de configuração do módulo LDAP aplicada"
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
