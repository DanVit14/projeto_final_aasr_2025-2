#!/bin/bash
# Script para testar a biblioteca LDAP diretamente

set +e

echo "=========================================="
echo "Testando Biblioteca LDAP"
echo "=========================================="
echo ""

# 1. Testar com variável de ambiente para ignorar certificado
echo "1. Testando ldapsearch com LDAPTLS_REQCERT=never:"
LDAPTLS_REQCERT=never docker-compose exec smtp ldapsearch -x -H ldaps://ldap:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -10
echo ""

# 2. Testar com debug LDAP
echo "2. Testando ldapsearch com debug (nível 1):"
docker-compose exec smtp ldapsearch -d 1 -x -H ldaps://ldap:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -20
echo ""

# 3. Testar usando IP direto com variável de ambiente
echo "3. Testando ldapsearch com IP direto e LDAPTLS_REQCERT=never:"
LDAPTLS_REQCERT=never docker-compose exec smtp ldapsearch -x -H ldaps://10.0.1.10:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -10
echo ""

# 4. Verificar se há arquivo de configuração LDAP do sistema
echo "4. Verificando configuração LDAP do sistema:"
docker-compose exec smtp cat /etc/ldap/ldap.conf 2>&1 | head -20 || echo "   Arquivo não existe"
echo ""

# 5. Criar/atualizar configuração LDAP do sistema
echo "5. Criando configuração LDAP do sistema para ignorar certificado:"
docker-compose exec smtp bash -c 'echo "TLS_REQCERT never" >> /etc/ldap/ldap.conf 2>&1 && echo "   ✓ Configuração adicionada" || echo "   ✗ Erro ao adicionar"'
echo ""

# 6. Testar novamente após configurar
echo "6. Testando ldapsearch após configurar TLS_REQCERT:"
docker-compose exec smtp ldapsearch -x -H ldaps://ldap:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -10
echo ""

# 7. Verificar se o Postfix usa a mesma biblioteca
echo "7. Verificando versão da biblioteca LDAP:"
docker-compose exec smtp ldapsearch -VV 2>&1 | head -5
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
