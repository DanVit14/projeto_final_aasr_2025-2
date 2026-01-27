#!/bin/bash
# Script para testar consulta LDAP do Postfix de forma verbosa

set +e

echo "=========================================="
echo "Testando Consulta LDAP do Postfix"
echo "=========================================="
echo ""

# 1. Testar postmap com saída de erro
echo "1. Testando postmap (com erros):"
docker-compose exec smtp postmap -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

# 2. Verificar se o usuário existe no LDAP
echo "2. Verificando se user1 existe no LDAP:"
docker-compose exec ldap ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(sAMAccountName=user1)" mail sAMAccountName 2>&1
echo ""

# 3. Verificar se há usuários com atributo mail
echo "3. Verificando usuários com atributo mail:"
docker-compose exec ldap ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=*)" mail sAMAccountName 2>&1 | head -20
echo ""

# 4. Testar consulta LDAP diretamente com o filtro usado pelo Postfix
echo "4. Testando consulta LDAP com o filtro do Postfix:"
docker-compose exec ldap ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(&(objectClass=person)(mail=user1@empresa.local))" sAMAccountName 2>&1
echo ""

# 5. Verificar configuração do arquivo LDAP
echo "5. Verificando configuração do arquivo LDAP:"
docker-compose exec smtp cat /etc/postfix/ldap/ldap-virtual-mailbox-maps.cf
echo ""

# 6. Testar conexão LDAPS do container SMTP
echo "6. Testando conexão LDAPS do container SMTP:"
docker-compose exec smtp ldapsearch -x -H ldaps://ldap:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -10
echo ""

# 7. Verificar logs do Postfix para erros LDAP
echo "7. Verificando logs do Docker para erros LDAP:"
docker-compose logs --tail=30 smtp 2>&1 | grep -iE "ldap|error|fail" | tail -10
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
