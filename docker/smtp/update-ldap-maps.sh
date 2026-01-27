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
mkdir -p "$HASH_DIR"

# Função para consultar LDAP
query_ldap() {
    local filter="$1"
    local attributes="$2"
    
    # Tentar LDAPS primeiro
    local result=$(ldapsearch -x -H ldaps://${LDAP_SERVER}:${LDAP_PORT} \
        -b "${LDAP_BASE}" \
        -D "${LDAP_BIND_DN}" \
        -w "${LDAP_BIND_PW}" \
        -LLL \
        -o nettimeout=5 \
        "${filter}" \
        ${attributes} 2>/dev/null)
    
    # Se falhar ou retornar vazio, tentar StartTLS
    if [ $? -ne 0 ] || [ -z "$result" ] || ! echo "$result" | grep -q "^[a-zA-Z]"; then
        result=$(ldapsearch -x -H ldap://${LDAP_SERVER}:389 \
            -b "${LDAP_BASE}" \
            -D "${LDAP_BIND_DN}" \
            -w "${LDAP_BIND_PW}" \
            -ZZ \
            -LLL \
            -o nettimeout=5 \
            "${filter}" \
            ${attributes} 2>/dev/null)
    fi
    
    echo "$result"
}

echo "Atualizando arquivos hash do LDAP..."
echo ""

# 1. Atualizar virtual-mailbox-domains.hash
echo "1. Atualizando virtual-mailbox-domains.hash..."
> "${HASH_DIR}/virtual-mailbox-domains.hash"
query_ldap "(mail=*)" "mail" | grep "^mail:" | cut -d: -f2 | tr -d " " | cut -d@ -f2 | sort -u | while read domain; do
    if [ -n "$domain" ]; then
        echo "$domain $domain" >> "${HASH_DIR}/virtual-mailbox-domains.hash"
    fi
done
postmap "${HASH_DIR}/virtual-mailbox-domains.hash" 2>/dev/null || true
domain_count=$(wc -l < "${HASH_DIR}/virtual-mailbox-domains.hash" 2>/dev/null || echo "0")
echo "   ✓ Domínios atualizados: $domain_count"

# 2. Atualizar virtual-mailbox-maps.hash
echo "2. Atualizando virtual-mailbox-maps.hash..."
> "${HASH_DIR}/virtual-mailbox-maps.hash"
# Processar resultado do LDAP usando awk para manter variáveis no mesmo shell
query_ldap "(&(objectClass=person)(mail=*))" "mail sAMAccountName" | awk '
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

# 3. Atualizar virtual-alias-maps.hash
echo "3. Atualizando virtual-alias-maps.hash..."
> "${HASH_DIR}/virtual-alias-maps.hash"
query_ldap "(&(objectClass=person)(mail=*))" "mail" | grep "^mail:" | cut -d: -f2 | tr -d " " | while read email; do
    if [ -n "$email" ]; then
        echo "$email $email" >> "${HASH_DIR}/virtual-alias-maps.hash"
    fi
done
postmap "${HASH_DIR}/virtual-alias-maps.hash" 2>/dev/null || true
alias_count=$(wc -l < "${HASH_DIR}/virtual-alias-maps.hash" 2>/dev/null || echo "0")
echo "   ✓ Aliases atualizados: $alias_count"

# 4. Atualizar sender-login-maps.hash
echo "4. Atualizando sender-login-maps.hash..."
> "${HASH_DIR}/sender-login-maps.hash"
query_ldap "(&(objectClass=person)(mail=*))" "mail sAMAccountName" | awk '
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

echo ""
echo "✓ Todos os arquivos hash foram atualizados!"
