#!/bin/bash
# Teste do LDAP - Samba AD DC

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "============================================================"
echo -e "${CYAN}  TESTE: LDAP (Samba AD DC)${NC}"
echo "============================================================"
echo ""

# 1. Samba rodando
echo -e "${CYAN}1. Verificar Samba AD DC:${NC}"
if docker-compose exec -T ldap samba-tool testparm -s 2>/dev/null | grep -q "workgroup"; then
    echo -e "${GREEN}✓ Samba configurado${NC}"
else
    echo -e "${RED}✗ Samba não configurado${NC}"
fi
echo ""

# 2. Listar usuários
echo -e "${CYAN}2. Usuários no domínio:${NC}"
docker-compose exec -T ldap samba-tool user list 2>/dev/null | head -10
echo ""

# 3. Conectividade
echo -e "${CYAN}3. Testar porta LDAP:${NC}"
if timeout 3 docker-compose exec -T cliente nc -zv ldap 389 2>&1 | grep -q "succeeded\|open"; then
    echo -e "${GREEN}✓ Porta 389 acessível${NC}"
else
    echo -e "${RED}✗ Porta 389 não acessível${NC}"
fi
echo ""

echo "============================================================"
echo -e "${GREEN}Teste do LDAP concluído${NC}"
echo "============================================================"
