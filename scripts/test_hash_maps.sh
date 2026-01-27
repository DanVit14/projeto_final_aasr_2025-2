#!/bin/bash
# Script para testar os arquivos hash do Postfix

set +e

echo "=========================================="
echo "Testando Arquivos Hash do Postfix"
echo "=========================================="
echo ""

# 1. Verificar se os arquivos existem
echo "1. Verificando se os arquivos hash existem:"
docker-compose exec smtp ls -la /etc/postfix/ldap/*.hash 2>&1
echo ""

# 2. Testar postmap com arquivos hash
echo "2. Testando postmap com virtual-mailbox-domains.hash:"
docker-compose exec smtp postmap -q empresa.local hash:/etc/postfix/ldap/virtual-mailbox-domains.hash 2>&1
echo ""

echo "3. Testando postmap com virtual-mailbox-maps.hash:"
docker-compose exec smtp postmap -q user1@empresa.local hash:/etc/postfix/ldap/virtual-mailbox-maps.hash 2>&1
echo ""

echo "4. Testando postmap com virtual-alias-maps.hash:"
docker-compose exec smtp postmap -q user1@empresa.local hash:/etc/postfix/ldap/virtual-alias-maps.hash 2>&1
echo ""

echo "5. Testando postmap com sender-login-maps.hash:"
docker-compose exec smtp postmap -q user1@empresa.local hash:/etc/postfix/ldap/sender-login-maps.hash 2>&1
echo ""

# 6. Verificar conteúdo dos arquivos (primeiras linhas)
echo "6. Conteúdo dos arquivos hash (primeiras linhas):"
echo "   virtual-mailbox-domains.hash:"
docker-compose exec smtp head -5 /etc/postfix/ldap/virtual-mailbox-domains.hash 2>&1
echo ""
echo "   virtual-mailbox-maps.hash:"
docker-compose exec smtp head -5 /etc/postfix/ldap/virtual-mailbox-maps.hash 2>&1
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
