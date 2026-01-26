#!/bin/bash
# Script de testes do LDAP/AD

set -e

echo "=========================================="
echo "Testes do LDAP/AD - Container 1"
echo "=========================================="
echo ""

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Teste 1: Listar usuários
echo "1. Testando listagem de usuários..."
if docker-compose exec -T ldap samba-tool user list > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Usuários encontrados:"
    docker-compose exec -T ldap samba-tool user list | sed 's/^/   - /'
else
    echo -e "${RED}✗ FALHOU${NC}"
fi
echo ""

# Teste 2: Informações do domínio (usando localhost)
echo "2. Testando informações do domínio..."
if docker-compose exec -T ldap samba-tool domain info localhost > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
    docker-compose exec -T ldap samba-tool domain info localhost | head -5
else
    echo -e "${YELLOW}⚠ Verificar manualmente${NC}"
fi
echo ""

# Teste 3: LDAP search (sem autenticação - anonymous)
echo "3. Testando busca LDAP (anonymous)..."
if docker-compose exec -T ldap ldapsearch -x -H ldap://localhost -b "dc=empresa,dc=local" -s base > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Base DN encontrada"
else
    echo -e "${RED}✗ FALHOU${NC}"
fi
echo ""

# Teste 4: LDAP search com autenticação (LDAPS)
echo "4. Testando autenticação LDAP (LDAPS)..."
if docker-compose exec -T ldap ldapsearch -x -H ldaps://localhost -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Autenticação funcionando"
else
    echo -e "${YELLOW}⚠ LDAPS pode não estar configurado (normal)${NC}"
fi
echo ""

# Teste 5: Listar grupos
echo "5. Testando listagem de grupos..."
if docker-compose exec -T ldap samba-tool group list > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Grupos encontrados:"
    docker-compose exec -T ldap samba-tool group list | sed 's/^/   - /'
else
    echo -e "${RED}✗ FALHOU${NC}"
fi
echo ""

# Teste 6: Verificar compartilhamentos SMB
echo "6. Testando compartilhamentos SMB..."
if docker-compose exec -T ldap test -d /shared/public && docker-compose exec -T ldap test -d /shared/private; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Compartilhamentos criados:"
    docker-compose exec -T ldap ls -ld /shared/* | awk '{print "   - " $9}'
else
    echo -e "${RED}✗ FALHOU${NC}"
fi
echo ""

# Teste 7: Verificar se o Samba está rodando
echo "7. Testando se o Samba está rodando..."
if docker-compose exec -T ldap smbclient -L localhost -N > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Samba está respondendo"
else
    echo -e "${YELLOW}⚠ Verificar manualmente${NC}"
fi
echo ""

echo "=========================================="
echo "Testes concluídos!"
echo "=========================================="
