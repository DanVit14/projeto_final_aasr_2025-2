#!/bin/bash
# Script para testar o update-ldap-maps.sh diretamente

set +e

echo "=========================================="
echo "Testando update-ldap-maps.sh"
echo "=========================================="
echo ""

# 1. Verificar se o script existe
echo "1. Verificando se o script existe:"
docker-compose exec smtp test -f /usr/local/bin/update-ldap-maps.sh && echo "   ✓ Script existe" || echo "   ✗ Script não existe"
echo ""

# 2. Verificar se é executável
echo "2. Verificando permissões:"
docker-compose exec smtp ls -la /usr/local/bin/update-ldap-maps.sh 2>&1
echo ""

# 3. Executar o script manualmente
echo "3. Executando script manualmente:"
docker-compose exec smtp /usr/local/bin/update-ldap-maps.sh 2>&1
echo ""

# 4. Verificar se os arquivos foram criados
echo "4. Verificando se os arquivos foram criados:"
docker-compose exec smtp ls -la /etc/postfix/ldap/*.hash 2>&1
echo ""

# 5. Verificar conteúdo dos arquivos
echo "5. Conteúdo dos arquivos (primeiras linhas):"
echo "   virtual-mailbox-domains.hash:"
docker-compose exec smtp head -5 /etc/postfix/ldap/virtual-mailbox-domains.hash 2>&1 || echo "   Arquivo vazio ou não existe"
echo ""
echo "   virtual-mailbox-maps.hash:"
docker-compose exec smtp head -5 /etc/postfix/ldap/virtual-mailbox-maps.hash 2>&1 || echo "   Arquivo vazio ou não existe"
echo ""

# 6. Testar postmap com os arquivos
echo "6. Testando postmap:"
docker-compose exec smtp postmap -q empresa.local hash:/etc/postfix/ldap/virtual-mailbox-domains.hash 2>&1
docker-compose exec smtp postmap -q user1@empresa.local hash:/etc/postfix/ldap/virtual-mailbox-maps.hash 2>&1
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
