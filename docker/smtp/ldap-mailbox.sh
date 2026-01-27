#!/bin/bash
# Script para consulta de mailbox via LDAP
set +e
KEY="$1"
LDAP_SERVER="${LDAP_SERVER:-ldap}"
LDAP_PORT="${LDAP_PORT:-636}"
LDAP_BASE="${LDAP_BASE:-dc=empresa,dc=local}"
LDAP_BIND_DN="${LDAP_BIND_DN:-cn=Administrator,cn=Users,dc=empresa,dc=local}"
LDAP_BIND_PW="${LDAP_BIND_PW:-Admin@123}"
if [ -z "$KEY" ]; then exit 1; fi
result=$(ldapsearch -x -H ldaps://${LDAP_SERVER}:${LDAP_PORT} -b "${LDAP_BASE}" -D "${LDAP_BIND_DN}" -w "${LDAP_BIND_PW}" -LLL -o nettimeout=5 "(&(objectClass=person)(mail=${KEY}))" "sAMAccountName" 2>/dev/null | grep "^sAMAccountName:" | head -1 | cut -d: -f2 | tr -d " ")
if [ -z "$result" ]; then
    result=$(ldapsearch -x -H ldap://${LDAP_SERVER}:389 -b "${LDAP_BASE}" -D "${LDAP_BIND_DN}" -w "${LDAP_BIND_PW}" -ZZ -LLL -o nettimeout=5 "(&(objectClass=person)(mail=${KEY}))" "sAMAccountName" 2>/dev/null | grep "^sAMAccountName:" | head -1 | cut -d: -f2 | tr -d " ")
fi
if [ -n "$result" ]; then
    domain=$(echo "$KEY" | cut -d@ -f2 2>/dev/null || echo "empresa.local")
    echo "${domain}/${result}/Maildir/"
fi
