#!/bin/bash
# Script para testar postmap com variáveis de ambiente LDAP

set +e

echo "=========================================="
echo "Testando postmap com variáveis de ambiente LDAP"
echo "=========================================="
echo ""

# 1. Testar postmap com LDAPTLS_REQCERT=never
echo "1. Testando postmap com LDAPTLS_REQCERT=never:"
LDAPTLS_REQCERT=never docker-compose exec smtp postmap -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

# 2. Testar postmap com múltiplas variáveis de ambiente
echo "2. Testando postmap com múltiplas variáveis LDAP:"
LDAPTLS_REQCERT=never LDAPCONF=/etc/ldap/ldap.conf docker-compose exec smtp postmap -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

# 3. Verificar se o Postfix está lendo /etc/ldap/ldap.conf
echo "3. Verificando se /etc/ldap/ldap.conf existe e tem TLS_REQCERT:"
docker-compose exec smtp cat /etc/ldap/ldap.conf 2>&1 | grep -i tls
echo ""

# 4. Testar postmap com debug e variável de ambiente
echo "4. Testando postmap com debug e LDAPTLS_REQCERT=never:"
LDAPTLS_REQCERT=never docker-compose exec smtp postmap -v -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1 | tail -20
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
