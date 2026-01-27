#!/bin/bash
# Script para debugar por que a consulta LDAP não está funcionando no update-ldap-maps.sh

set +e

echo "=========================================="
echo "Debug: Consulta LDAP"
echo "=========================================="
echo ""

# Configurações
LDAP_SERVER="${LDAP_SERVER:-ldap}"
LDAP_PORT="${LDAP_PORT:-636}"
LDAP_BASE="${LDAP_BASE:-dc=empresa,dc=local}"
LDAP_BIND_DN="${LDAP_BIND_DN:-cn=Administrator,cn=Users,dc=empresa,dc=local}"
LDAP_BIND_PW="${LDAP_BIND_PW:-Admin@123}"

echo "1. Testando LDAPS diretamente:"
docker-compose exec smtp ldapsearch -x -H ldaps://${LDAP_SERVER}:${LDAP_PORT} \
    -b "${LDAP_BASE}" \
    -D "${LDAP_BIND_DN}" \
    -w "${LDAP_BIND_PW}" \
    -LLL \
    -o nettimeout=5 \
    "(mail=*)" \
    "mail" 2>&1 | head -20
echo ""

echo "2. Testando LDAP com StartTLS:"
docker-compose exec smtp ldapsearch -x -H ldap://${LDAP_SERVER}:389 \
    -b "${LDAP_BASE}" \
    -D "${LDAP_BIND_DN}" \
    -w "${LDAP_BIND_PW}" \
    -ZZ \
    -LLL \
    -o nettimeout=5 \
    "(mail=*)" \
    "mail" 2>&1 | head -20
echo ""

echo "3. Testando consulta completa (mail + sAMAccountName):"
docker-compose exec smtp ldapsearch -x -H ldaps://${LDAP_SERVER}:${LDAP_PORT} \
    -b "${LDAP_BASE}" \
    -D "${LDAP_BIND_DN}" \
    -w "${LDAP_BIND_PW}" \
    -LLL \
    -o nettimeout=5 \
    "(&(objectClass=person)(mail=*))" \
    "mail sAMAccountName" 2>&1 | head -30
echo ""

echo "4. Verificando se há erros específicos:"
docker-compose exec smtp ldapsearch -x -H ldaps://${LDAP_SERVER}:${LDAP_PORT} \
    -b "${LDAP_BASE}" \
    -D "${LDAP_BIND_DN}" \
    -w "${LDAP_BIND_PW}" \
    -LLL \
    -o nettimeout=5 \
    "(mail=*)" \
    "mail" 2>&1 | grep -iE "error|fail|can't|unable" || echo "   Nenhum erro encontrado"
echo ""

echo "=========================================="
echo "Debug concluído!"
echo "=========================================="
