#!/bin/bash
# Script para verificar se há usuários no LDAP e testar consultas

set +e

echo "=========================================="
echo "Teste: Verificando usuários no LDAP"
echo "=========================================="
echo ""

# Configurações
LDAP_SERVER="${LDAP_SERVER:-ldap}"
LDAP_PORT="${LDAP_PORT:-636}"
LDAP_BASE="${LDAP_BASE:-dc=empresa,dc=local}"
LDAP_BIND_DN="${LDAP_BIND_DN:-cn=Administrator,cn=Users,dc=empresa,dc=local}"
LDAP_BIND_PW="${LDAP_BIND_PW:-Admin@123}"

echo "1. Listando todos os usuários (objectClass=person):"
docker-compose exec smtp ldapsearch -x -H ldaps://${LDAP_SERVER}:${LDAP_PORT} \
    -b "${LDAP_BASE}" \
    -D "${LDAP_BIND_DN}" \
    -w "${LDAP_BIND_PW}" \
    -LLL \
    -o nettimeout=5 \
    "(objectClass=person)" \
    "sAMAccountName mail" 2>&1 | grep -v "^#" | head -30
echo ""

echo "2. Contando usuários com email:"
count=$(docker-compose exec smtp ldapsearch -x -H ldaps://${LDAP_SERVER}:${LDAP_PORT} \
    -b "${LDAP_BASE}" \
    -D "${LDAP_BIND_DN}" \
    -w "${LDAP_BIND_PW}" \
    -LLL \
    -o nettimeout=5 \
    "(&(objectClass=person)(mail=*))" \
    "mail" 2>&1 | grep -v "^#" | grep -c "^mail:" || echo "0")
echo "   Total de usuários com email: $count"
echo ""

echo "3. Listando emails encontrados:"
docker-compose exec smtp ldapsearch -x -H ldaps://${LDAP_SERVER}:${LDAP_PORT} \
    -b "${LDAP_BASE}" \
    -D "${LDAP_BIND_DN}" \
    -w "${LDAP_BIND_PW}" \
    -LLL \
    -o nettimeout=5 \
    "(mail=*)" \
    "mail" 2>&1 | grep -v "^#" | grep "^mail:" | head -10
echo ""

echo "4. Testando consulta completa (mail + sAMAccountName):"
docker-compose exec smtp ldapsearch -x -H ldaps://${LDAP_SERVER}:${LDAP_PORT} \
    -b "${LDAP_BASE}" \
    -D "${LDAP_BIND_DN}" \
    -w "${LDAP_BIND_PW}" \
    -LLL \
    -o nettimeout=5 \
    "(&(objectClass=person)(mail=*))" \
    "mail sAMAccountName" 2>&1 | grep -v "^#" | head -20
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
