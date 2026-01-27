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

# Garantir permissões corretas
chown root:root "$HASH_DIR" 2>/dev/null || true
chmod 755 "$HASH_DIR" 2>/dev/null || true

# Função para consultar LDAP
query_ldap() {
    local filter="$1"
    local attributes="$2"
    local result=""
    local exit_code=0
    local has_data=0
    
    # Tentar LDAPS primeiro
    result=$(ldapsearch -x -H ldaps://${LDAP_SERVER}:${LDAP_PORT} \
        -b "${LDAP_BASE}" \
        -D "${LDAP_BIND_DN}" \
        -w "${LDAP_BIND_PW}" \
        -LLL \
        -o nettimeout=5 \
        "${filter}" \
        ${attributes} 2>&1)
    exit_code=$?
    
    # Filtrar referências (linhas que começam com #) e verificar se há dados reais
    if [ $exit_code -eq 0 ] && [ -n "$result" ]; then
        # Remover linhas de referência e verificar se sobrou algo útil
        filtered_result=$(echo "$result" | grep -v "^#")
        if [ -n "$filtered_result" ] && echo "$filtered_result" | grep -qE "^(dn|mail|sAMAccountName):"; then
            echo "$filtered_result"
            return 0
        fi
    fi
    
    # Tentar StartTLS se LDAPS falhou
    result=$(ldapsearch -x -H ldap://${LDAP_SERVER}:389 \
        -b "${LDAP_BASE}" \
        -D "${LDAP_BIND_DN}" \
        -w "${LDAP_BIND_PW}" \
        -ZZ \
        -LLL \
        -o nettimeout=5 \
        "${filter}" \
        ${attributes} 2>&1)
    exit_code=$?
    
    # Filtrar referências e verificar se há dados reais
    if [ $exit_code -eq 0 ] && [ -n "$result" ]; then
        filtered_result=$(echo "$result" | grep -v "^#")
        if [ -n "$filtered_result" ] && echo "$filtered_result" | grep -qE "^(dn|mail|sAMAccountName):"; then
            echo "$filtered_result"
            return 0
        fi
    fi
    
    # Se ambos falharam, retornar vazio
    return 1
}

echo "Atualizando arquivos hash do LDAP..."
echo ""

# 1. Atualizar virtual-mailbox-domains.hash
echo "1. Atualizando virtual-mailbox-domains.hash..."
rm -f "${HASH_DIR}/virtual-mailbox-domains.hash" "${HASH_DIR}/virtual-mailbox-domains.hash.db" 2>/dev/null
ldap_result=$(query_ldap "(mail=*)" "mail")
query_exit=$?
if [ $query_exit -eq 0 ] && [ -n "$ldap_result" ] && echo "$ldap_result" | grep -q "^mail:"; then
    # Usar process substitution para evitar problema de subshell
    {
        echo "$ldap_result" | grep "^mail:" | cut -d: -f2 | tr -d " " | cut -d@ -f2 | sort -u | while read domain; do
            if [ -n "$domain" ]; then
                echo "$domain $domain"
            fi
        done
    } > "${HASH_DIR}/virtual-mailbox-domains.hash"
else
    echo "   ⚠ Não foi possível consultar LDAP, criando entrada padrão"
    echo "empresa.local empresa.local" > "${HASH_DIR}/virtual-mailbox-domains.hash"
fi

# Garantir que o arquivo existe e fazer postmap
if [ -f "${HASH_DIR}/virtual-mailbox-domains.hash" ]; then
    postmap "${HASH_DIR}/virtual-mailbox-domains.hash" 2>&1
    if [ -f "${HASH_DIR}/virtual-mailbox-domains.hash.db" ]; then
        domain_count=$(wc -l < "${HASH_DIR}/virtual-mailbox-domains.hash" 2>/dev/null || echo "0")
        echo "   ✓ Domínios atualizados: $domain_count"
    else
        echo "   ⚠ postmap falhou, mas arquivo .hash existe"
    fi
else
    echo "   ✗ ERRO: Arquivo não foi criado"
fi

# 2. Atualizar virtual-mailbox-maps.hash
echo "2. Atualizando virtual-mailbox-maps.hash..."
rm -f "${HASH_DIR}/virtual-mailbox-maps.hash" "${HASH_DIR}/virtual-mailbox-maps.hash.db" 2>/dev/null
ldap_result=$(query_ldap "(&(objectClass=person)(mail=*))" "mail sAMAccountName")
query_exit=$?
if [ $query_exit -eq 0 ] && [ -n "$ldap_result" ] && echo "$ldap_result" | grep -qE "^(mail|sAMAccountName):"; then
    # Processar resultado do LDAP usando awk
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
    }' > "${HASH_DIR}/virtual-mailbox-maps.hash"
else
    echo "   ⚠ Não foi possível consultar LDAP, criando arquivo vazio"
    touch "${HASH_DIR}/virtual-mailbox-maps.hash"
fi

# Garantir que o arquivo existe e fazer postmap
if [ -f "${HASH_DIR}/virtual-mailbox-maps.hash" ]; then
    postmap "${HASH_DIR}/virtual-mailbox-maps.hash" 2>&1
    if [ -f "${HASH_DIR}/virtual-mailbox-maps.hash.db" ]; then
        mailbox_count=$(wc -l < "${HASH_DIR}/virtual-mailbox-maps.hash" 2>/dev/null || echo "0")
        echo "   ✓ Caixas de correio atualizadas: $mailbox_count"
    else
        echo "   ⚠ postmap falhou, mas arquivo .hash existe"
    fi
else
    echo "   ✗ ERRO: Arquivo não foi criado"
fi

# 3. Atualizar virtual-alias-maps.hash
echo "3. Atualizando virtual-alias-maps.hash..."
rm -f "${HASH_DIR}/virtual-alias-maps.hash" "${HASH_DIR}/virtual-alias-maps.hash.db" 2>/dev/null
ldap_result=$(query_ldap "(&(objectClass=person)(mail=*))" "mail")
query_exit=$?
if [ $query_exit -eq 0 ] && [ -n "$ldap_result" ] && echo "$ldap_result" | grep -q "^mail:"; then
    # Usar process substitution para evitar problema de subshell
    {
        echo "$ldap_result" | grep "^mail:" | cut -d: -f2 | tr -d " " | while read email; do
            if [ -n "$email" ]; then
                echo "$email $email"
            fi
        done
    } > "${HASH_DIR}/virtual-alias-maps.hash"
else
    echo "   ⚠ Não foi possível consultar LDAP, criando arquivo vazio"
    touch "${HASH_DIR}/virtual-alias-maps.hash"
fi

# Garantir que o arquivo existe e fazer postmap
if [ -f "${HASH_DIR}/virtual-alias-maps.hash" ]; then
    postmap "${HASH_DIR}/virtual-alias-maps.hash" 2>&1
    if [ -f "${HASH_DIR}/virtual-alias-maps.hash.db" ]; then
        alias_count=$(wc -l < "${HASH_DIR}/virtual-alias-maps.hash" 2>/dev/null || echo "0")
        echo "   ✓ Aliases atualizados: $alias_count"
    else
        echo "   ⚠ postmap falhou, mas arquivo .hash existe"
    fi
else
    echo "   ✗ ERRO: Arquivo não foi criado"
fi

# 4. Atualizar sender-login-maps.hash
echo "4. Atualizando sender-login-maps.hash..."
rm -f "${HASH_DIR}/sender-login-maps.hash" "${HASH_DIR}/sender-login-maps.hash.db" 2>/dev/null
ldap_result=$(query_ldap "(&(objectClass=person)(mail=*))" "mail sAMAccountName")
query_exit=$?
if [ $query_exit -eq 0 ] && [ -n "$ldap_result" ] && echo "$ldap_result" | grep -qE "^(mail|sAMAccountName):"; then
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
    }' > "${HASH_DIR}/sender-login-maps.hash"
else
    echo "   ⚠ Não foi possível consultar LDAP, criando arquivo vazio"
    touch "${HASH_DIR}/sender-login-maps.hash"
fi

# Garantir que o arquivo existe e fazer postmap
if [ -f "${HASH_DIR}/sender-login-maps.hash" ]; then
    postmap "${HASH_DIR}/sender-login-maps.hash" 2>&1
    if [ -f "${HASH_DIR}/sender-login-maps.hash.db" ]; then
        sender_count=$(wc -l < "${HASH_DIR}/sender-login-maps.hash" 2>/dev/null || echo "0")
        echo "   ✓ Sender login maps atualizados: $sender_count"
    else
        echo "   ⚠ postmap falhou, mas arquivo .hash existe"
    fi
else
    echo "   ✗ ERRO: Arquivo não foi criado"
fi

echo ""
echo "Criando Maildirs (new, cur, tmp) para cada caixa..."
VIRTUAL_BASE="${VIRTUAL_MAILBOX_BASE:-/var/mail/vhosts}"
if [ -f "${HASH_DIR}/virtual-mailbox-maps.hash" ]; then
    while read -r email path_rest; do
        if [ -n "$path_rest" ]; then
            mdir="${VIRTUAL_BASE}/${path_rest}"
            for sub in new cur tmp; do
                mkdir -p "${mdir}${sub}"
            done
            chown -R postfix:postfix "${mdir}" 2>/dev/null || true
        fi
    done < "${HASH_DIR}/virtual-mailbox-maps.hash"
    echo "   ✓ Maildirs criados/atualizados"
fi

echo ""
echo "Verificando arquivos criados..."
ls -la "${HASH_DIR}"/*.hash 2>/dev/null | head -4 || echo "   ⚠ Nenhum arquivo .hash encontrado"
ls -la "${HASH_DIR}"/*.db 2>/dev/null | head -4 || echo "   ⚠ Nenhum arquivo .db encontrado"
echo ""
echo "✓ Processo de atualização concluído!"
