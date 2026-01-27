#!/bin/bash
# Script para consulta de sender login via LDAP
# Chamado pelo Postfix: external:/usr/local/bin/ldap-sender.sh
# Postfix passa: /usr/local/bin/ldap-sender.sh user1@empresa.local

set +e

KEY="$1"

# Configurações LDAP
LDAP_SERVER="${LDAP_SERVER:-ldap}"
LDAP_PORT="${LDAP_PORT:-636}"
LDAP_BASE="${LDAP_BASE:-dc=empresa,dc=local}"
LDAP_BIND_DN="${LDAP_BIND_DN:-cn=Administrator,cn=Users,dc=empresa,dc=local}"
LDAP_BIND_PW="${LDAP_BIND_PW:-Admin@123}"

if [ -z "$KEY" ]; then
    exit 1
fi

# Consultar LDAP
result=$(ldapsearch -x -H ldaps://${LDAP_SERVER}:${LDAP_PORT} \
    -b "${LDAP_BASE}" \
    -D "${LDAP_BIND_DN}" \
    -w "${LDAP_BIND_PW}" \
    -LLL \
    -o nettimeout=5 \
    "(&(objectClass=person)(mail=${KEY}))" \
    "sAMAccountName" 2>/dev/null | grep "^sAMAccountName:" | head -1 | cut -d: -f2 | tr -d " ")

# Se falhar, tentar StartTLS
if [ -z "$result" ]; then
    result=$(ldapsearch -x -H ldap://${LDAP_SERVER}:389 \
        -b "${LDAP_BASE}" \
        -D "${LDAP_BIND_DN}" \
        -w "${LDAP_BIND_PW}" \
        -ZZ \
        -LLL \
        -o nettimeout=5 \
        "(&(objectClass=person)(mail=${KEY}))" \
        "sAMAccountName" 2>/dev/null | grep "^sAMAccountName:" | head -1 | cut -d: -f2 | tr -d " ")
fi

# Retornar sAMAccountName se encontrado
if [ -n "$result" ]; then
    echo "$result"
fi
