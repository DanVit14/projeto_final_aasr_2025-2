#!/bin/bash
# Script para testar os scripts wrapper LDAP

set +e

echo "=========================================="
echo "Testando Scripts Wrapper LDAP"
echo "=========================================="
echo ""

# 1. Testar mailbox
echo "1. Testando ldap-mailbox.sh (user1@empresa.local):"
docker-compose exec smtp /usr/local/bin/ldap-mailbox.sh user1@empresa.local 2>&1
echo ""

# 2. Testar domain
echo "2. Testando ldap-domain.sh (empresa.local):"
docker-compose exec smtp /usr/local/bin/ldap-domain.sh empresa.local 2>&1
echo ""

# 3. Testar alias
echo "3. Testando ldap-alias.sh (user1@empresa.local):"
docker-compose exec smtp /usr/local/bin/ldap-alias.sh user1@empresa.local 2>&1
echo ""

# 4. Testar sender
echo "4. Testando ldap-sender.sh (user1@empresa.local):"
docker-compose exec smtp /usr/local/bin/ldap-sender.sh user1@empresa.local 2>&1
echo ""

# 5. Testar usando postmap com external lookup
echo "5. Testando postmap com external lookup (mailbox):"
docker-compose exec smtp postmap -q "user1@empresa.local" "external:/usr/local/bin/ldap-mailbox.sh" 2>&1
echo ""

# 6. Testar domain lookup
echo "6. Testando postmap com external lookup (domain):"
docker-compose exec smtp postmap -q "empresa.local" "external:/usr/local/bin/ldap-domain.sh" 2>&1
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
