#!/bin/bash
# Script para atualizar arquivos hash do Postfix com dados do LDAP
# Este script consulta o LDAP e atualiza os arquivos hash que o Postfix usa

set +e

# Configurações LDAP
LDAP_SERVER="${LDAP_SERVER:-ldap}"
LDAP_PORT="${LDAP_PORT:-636}"
LDAP_BASE="${LDAP_BASE:-dc=empresa,dc=local}"
LDAP_BIND_DN="${LDAP_BIND_DN:-cn=Administrator,cn=Users,dc=empresa,dc=local}"
LDAP_BIND_PW="${LDAP_BIND_PW:-Admin@123}"

# Diretório dos arquivos hash
HASH_DIR="/etc/postfix/ldap"
mkdir -p "$HASH_DIR" || {
    echo "ERRO: Não foi possível criar diretório $HASH_DIR" >&2
    exit 1
}

# Função para consultar LDAP
query_ldap() {
    local filter="$1"
    local attributes="$2"
    local result=""
    
    # Tentar LDAPS primeiro
    result=$(ldapsearch -x -H ldaps://${LDAP_SERVER}:${LDAP_PORT} \
        -b "${LDAP_BASE}" \
        -D "${LDAP_BIND_DN}" \
        -w "${LDAP_BIND_PW}" \
        -LLL \
        -o nettimeout=5 \
        "${filter}" \
        ${attributes} 2>&1)
    
    # Verificar se funcionou (procurar por linhas que começam com atributo ou "dn:")
    if [ $? -ne 0 ] || [ -z "$result" ] || ! echo "$result" | grep -qE "^(dn|mail|sAMAccountName):"; then
        # Tentar StartTLS
        result=$(ldapsearch -x -H ldap://${LDAP_SERVER}:389 \
            -b "${LDAP_BASE}" \
            -D "${LDAP_BIND_DN}" \
            -w "${LDAP_BIND_PW}" \
            -ZZ \
            -LLL \
            -o nettimeout=5 \
            "${filter}" \
            ${attributes} 2>&1)
    fi
    
    # Se ainda falhar, retornar vazio mas não dar erro fatal
    if [ $? -ne 0 ] || ! echo "$result" | grep -qE "^(dn|mail|sAMAccountName):"; then
        echo "" >&2
        return 1
    fi
    
    echo "$result"
    return 0
}

echo "Atualizando arquivos hash do LDAP..."
echo ""

# 1. Atualizar virtual-mailbox-domains.hash
echo "1. Atualizando virtual-mailbox-domains.hash..."
> "${HASH_DIR}/virtual-mailbox-domains.hash"
ldap_result=$(query_ldap "(mail=*)" "mail")
if [ $? -eq 0 ] && [ -n "$ldap_result" ]; then
    echo "$ldap_result" | grep "^mail:" | cut -d: -f2 | tr -d " " | cut -d@ -f2 | sort -u | while read domain; do
        if [ -n "$domain" ]; then
            echo "$domain $domain" >> "${HASH_DIR}/virtual-mailbox-domains.hash"
        fi
    done
    postmap "${HASH_DIR}/virtual-mailbox-domains.hash" 2>/dev/null || true
    domain_count=$(wc -l < "${HASH_DIR}/virtual-mailbox-domains.hash" 2>/dev/null || echo "0")
    echo "   ✓ Domínios atualizados: $domain_count"
else
    echo "   ⚠ Não foi possível consultar LDAP, criando entrada padrão"
    echo "empresa.local empresa.local" >> "${HASH_DIR}/virtual-mailbox-domains.hash"
    postmap "${HASH_DIR}/virtual-mailbox-domains.hash" 2>/dev/null || true
    echo "   ✓ Arquivo criado com entrada padrão"
fi

# 2. Atualizar virtual-mailbox-maps.hash
echo "2. Atualizando virtual-mailbox-maps.hash..."
> "${HASH_DIR}/virtual-mailbox-maps.hash"
ldap_result=$(query_ldap "(&(objectClass=person)(mail=*))" "mail sAMAccountName")
if [ $? -eq 0 ] && [ -n "$ldap_result" ]; then
    # Processar resultado do LDAP usando awk para manter variáveis no mesmo shell
    echo "$ldap_result" | awk '
    BEGIN { email=""; username="" }
    /^mail: / { email=$2 }
    /^sAMAccountName: / { username=$2 }
    /^$/ {
        if (email != "" && username != "") {
            split(email, parts, "@")
            domain = parts[2]
            print email " " domain "/" username "/Maildir/"
        }
        email=""
        username=""
    }
    END {
        if (email != "" && username != "") {
            split(email, parts, "@")
            domain = parts[2]
            print email " " domain "/" username "/Maildir/"
        }
    }' >> "${HASH_DIR}/virtual-mailbox-maps.hash"
    postmap "${HASH_DIR}/virtual-mailbox-maps.hash" 2>/dev/null || true
    mailbox_count=$(wc -l < "${HASH_DIR}/virtual-mailbox-maps.hash" 2>/dev/null || echo "0")
    echo "   ✓ Caixas de correio atualizadas: $mailbox_count"
else
    echo "   ⚠ Não foi possível consultar LDAP, arquivo será criado vazio"
    postmap "${HASH_DIR}/virtual-mailbox-maps.hash" 2>/dev/null || true
    echo "   ✓ Arquivo criado (vazio)"
fi

# 3. Atualizar virtual-alias-maps.hash
echo "3. Atualizando virtual-alias-maps.hash..."
> "${HASH_DIR}/virtual-alias-maps.hash"
ldap_result=$(query_ldap "(&(objectClass=person)(mail=*))" "mail")
if [ $? -eq 0 ] && [ -n "$ldap_result" ]; then
    echo "$ldap_result" | grep "^mail:" | cut -d: -f2 | tr -d " " | while read email; do
        if [ -n "$email" ]; then
            echo "$email $email" >> "${HASH_DIR}/virtual-alias-maps.hash"
        fi
    done
    postmap "${HASH_DIR}/virtual-alias-maps.hash" 2>/dev/null || true
    alias_count=$(wc -l < "${HASH_DIR}/virtual-alias-maps.hash" 2>/dev/null || echo "0")
    echo "   ✓ Aliases atualizados: $alias_count"
else
    echo "   ⚠ Não foi possível consultar LDAP, arquivo será criado vazio"
    postmap "${HASH_DIR}/virtual-alias-maps.hash" 2>/dev/null || true
    echo "   ✓ Arquivo criado (vazio)"
fi

# 4. Atualizar sender-login-maps.hash
echo "4. Atualizando sender-login-maps.hash..."
> "${HASH_DIR}/sender-login-maps.hash"
ldap_result=$(query_ldap "(&(objectClass=person)(mail=*))" "mail sAMAccountName")
if [ $? -eq 0 ] && [ -n "$ldap_result" ]; then
    echo "$ldap_result" | awk '
    BEGIN { email=""; username="" }
    /^mail: / { email=$2 }
    /^sAMAccountName: / { username=$2 }
    /^$/ {
        if (email != "" && username != "") {
            print email " " username
        }
        email=""
        username=""
    }
    END {
        if (email != "" && username != "") {
            print email " " username
        }
    }' >> "${HASH_DIR}/sender-login-maps.hash"
    postmap "${HASH_DIR}/sender-login-maps.hash" 2>/dev/null || true
    sender_count=$(wc -l < "${HASH_DIR}/sender-login-maps.hash" 2>/dev/null || echo "0")
    echo "   ✓ Sender login maps atualizados: $sender_count"
else
    echo "   ⚠ Não foi possível consultar LDAP, arquivo será criado vazio"
    postmap "${HASH_DIR}/sender-login-maps.hash" 2>/dev/null || true
    echo "   ✓ Arquivo criado (vazio)"
fi

echo ""
echo "✓ Todos os arquivos hash foram atualizados!"
