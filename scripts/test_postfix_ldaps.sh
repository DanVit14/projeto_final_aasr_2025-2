#!/bin/bash
# Script para testar se o Postfix consegue usar LDAPS

set +e

echo "=========================================="
echo "Testando Postfix com LDAPS"
echo "=========================================="
echo ""

# 1. Verificar se os arquivos estão configurados para LDAPS
echo "1. Verificando configuração dos arquivos LDAP:"
echo "   ldap-virtual-mailbox-maps.cf:"
docker-compose exec smtp grep -E "server_port|start_tls" /etc/postfix/ldap/ldap-virtual-mailbox-maps.cf
echo ""

# 2. Testar resolução Postfix com LDAPS
echo "2. Testando resolução Postfix do destinatário (LDAPS):"
docker-compose exec smtp postmap -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

# 3. Verificar logs do Postfix para erros LDAP
echo "3. Verificando logs do Docker para erros LDAP:"
docker-compose logs --tail=50 smtp 2>&1 | grep -iE "ldap|636|error|fail" | tail -10
echo ""

# 4. Testar conexão LDAPS diretamente
echo "4. Testando conexão LDAPS diretamente:"
docker-compose exec smtp ldapsearch -x -H ldaps://ldap:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=user1@empresa.local)" mail sAMAccountName 2>&1 | head -10
echo ""

# 5. Verificar se o Postfix precisa de certificados
echo "5. Verificando certificados SSL disponíveis:"
docker-compose exec smtp ls -la /etc/ssl/certs/ | grep -i ca | head -5
echo ""

# 6. Verificar configuração do Postfix para LDAP
echo "6. Verificando configuração LDAP do Postfix:"
docker-compose exec smtp postconf | grep -i ldap | head -5
echo ""

# 7. Tentar recarregar Postfix e testar novamente
echo "7. Recarregando Postfix e testando novamente:"
docker-compose exec smtp postfix reload 2>&1 | head -3
sleep 2
docker-compose exec smtp postmap -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
