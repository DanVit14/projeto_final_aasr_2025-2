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
sleep 3

# Teste 2: Informações do domínio (usando localhost)
echo "2. Testando informações do domínio..."
DOMAIN_INFO=$(docker-compose exec -T ldap samba-tool domain info localhost 2>&1)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "$DOMAIN_INFO" | head -10 | sed 's/^/   /'
else
    echo -e "${YELLOW}⚠ Verificar manualmente${NC}"
    echo "   Tentando método alternativo..."
    # Tentar sem especificar host
    docker-compose exec -T ldap samba-tool domain info 2>&1 | head -5 | sed 's/^/   /' || echo "   Não foi possível obter informações do domínio"
fi
echo ""
sleep 3

# Teste 3: LDAP search (sem autenticação - anonymous)
echo "3. Testando busca LDAP (anonymous)..."
LDAP_ANON=$(docker-compose exec -T ldap ldapsearch -x -H ldap://localhost -b "dc=empresa,dc=local" -s base 2>&1)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Base DN encontrada"
    echo "$LDAP_ANON" | grep -i "dn:" | head -3 | sed 's/^/   /' || echo "   Conexão LDAP anônima funcionando"
else
    echo -e "${RED}✗ FALHOU${NC}"
    echo "   Motivo: Busca LDAP anônima não permitida (normal por segurança)"
    echo "   Detalhes: $(echo "$LDAP_ANON" | grep -i "error\|bind" | head -1 | sed 's/^/     /')"
fi
echo ""
sleep 3

# Teste 4: LDAP search com autenticação (LDAPS)
echo "4. Testando autenticação LDAP (LDAPS)..."
LDAP_AUTH=$(docker-compose exec -T ldap ldapsearch -x -H ldaps://localhost -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" 2>&1)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Autenticação LDAPS funcionando"
    echo "$LDAP_AUTH" | grep -i "dn:" | head -3 | sed 's/^/   /' || echo "   Conexão autenticada bem-sucedida"
else
    echo -e "${YELLOW}⚠ LDAPS pode não estar configurado (normal)${NC}"
    echo "   Tentando LDAP normal com autenticação..."
    LDAP_NORMAL=$(docker-compose exec -T ldap ldapsearch -x -H ldap://localhost -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" 2>&1)
    if [ $? -eq 0 ]; then
        echo "   ✓ LDAP normal com autenticação funciona"
        echo "$LDAP_NORMAL" | grep -i "dn:" | head -3 | sed 's/^/     /' || echo "     Autenticação funcionando"
    else
        echo "   Detalhes: $(echo "$LDAP_AUTH" | grep -i "error\|certificate\|ssl" | head -1 | sed 's/^/     /')"
    fi
fi
echo ""
sleep 3

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
sleep 3

# Teste 6: Verificar compartilhamentos SMB
echo "6. Testando compartilhamentos SMB..."
if docker-compose exec -T ldap test -d /shared/public && docker-compose exec -T ldap test -d /shared/private; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Compartilhamentos criados:"
    docker-compose exec -T ldap ls -ld /shared/public /shared/private 2>/dev/null | awk '{print "   - " $9}' || echo "   - /shared/public" && echo "   - /shared/private"
else
    echo -e "${RED}✗ FALHOU${NC}"
fi
echo ""
sleep 3

# Teste 7: Verificar se o Samba está rodando
echo "7. Testando se o Samba está rodando..."
# Verificar múltiplas formas para ter certeza
SAMBA_OK=false

# Método 1: Verificar se o processo samba está rodando
if docker-compose exec -T ldap pgrep -x samba > /dev/null 2>&1; then
    SAMBA_OK=true
    echo "   ✓ Processo Samba encontrado"
fi

# Método 2: Verificar se a porta 445 está ouvindo
if docker-compose exec -T ldap netstat -tuln 2>/dev/null | grep -q ":445 " || \
   docker-compose exec -T ldap ss -tuln 2>/dev/null | grep -q ":445 "; then
    SAMBA_OK=true
    echo "   ✓ Porta 445 (SMB) está ouvindo"
fi

# Método 3: Tentar conexão SMB
if docker-compose exec -T ldap timeout 3 smbclient -L localhost -N > /dev/null 2>&1; then
    SAMBA_OK=true
    echo "   ✓ Conexão SMB bem-sucedida"
    echo "   Compartilhamentos disponíveis:"
    docker-compose exec -T ldap smbclient -L localhost -N 2>/dev/null | grep -E "^[[:space:]]+[A-Z]" | head -5 | sed 's/^/     - /' || true
fi

# Resultado final
if [ "$SAMBA_OK" = true ]; then
    echo -e "${GREEN}✓ OK - Samba está rodando e funcionando${NC}"
else
    echo -e "${RED}✗ FALHOU - Samba não está respondendo${NC}"
fi
echo ""

echo "=========================================="
echo "Testes concluídos!"
echo "=========================================="
