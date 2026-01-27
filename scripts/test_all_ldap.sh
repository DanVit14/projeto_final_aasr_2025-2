#!/bin/bash
# Script completo para testar todas as consultas LDAP

set +e

echo "=========================================="
echo "Teste Completo de LDAP"
echo "=========================================="
echo ""

echo "1. Testando postmap (domínio):"
docker-compose exec smtp postmap -q empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-domains.cf 2>&1
echo ""

echo "2. Testando postmap (caixa de correio):"
docker-compose exec smtp postmap -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

echo "3. Testando postmap (alias):"
docker-compose exec smtp postmap -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-alias-maps.cf 2>&1
echo ""

echo "4. Buscando user1 no LDAP (sAMAccountName):"
docker-compose exec ldap ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(sAMAccountName=user1)" mail sAMAccountName 2>&1
echo ""

echo "5. Buscando user1 no LDAP (mail):"
docker-compose exec ldap ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=user1@empresa.local)" sAMAccountName 2>&1
echo ""

echo "6. Testando LDAPS do container SMTP:"
docker-compose exec smtp ldapsearch -x -H ldaps://ldap:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -10
echo ""

echo "7. Verificando configuração LDAP do Postfix:"
docker-compose exec smtp cat /etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

echo "8. Verificando logs para erros LDAP:"
docker-compose logs --tail=30 smtp 2>&1 | grep -iE "ldap|error|fail" | tail -10
echo ""

echo "=========================================="
echo "Teste completo concluído!"
echo "=========================================="
