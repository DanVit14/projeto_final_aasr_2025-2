#!/bin/bash
# Teste do SMTP - Postfix

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "============================================================"
echo -e "${CYAN}  TESTE: SMTP (Postfix)${NC}"
echo "============================================================"
echo ""

# 1. Postfix rodando
echo -e "${CYAN}1. Verificar Postfix:${NC}"
if docker-compose exec -T smtp pgrep -x master >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Processo Postfix (master) rodando${NC}"
else
    echo -e "${RED}✗ Postfix não está rodando${NC}"
fi
echo ""

# 2. Porta SMTP
echo -e "${CYAN}2. Testar porta SMTP:${NC}"
if docker-compose exec -T cliente timeout 3 bash -c "echo > /dev/tcp/smtp/25" 2>/dev/null; then
    echo -e "${GREEN}✓ Porta 25 acessível${NC}"
else
    echo -e "${RED}✗ Porta 25 não acessível${NC}"
fi
echo ""

# 3. Fila de emails
echo -e "${CYAN}3. Verificar fila:${NC}"
docker-compose exec -T smtp mailq 2>/dev/null || echo "(comando mailq não disponível)"
echo ""

echo "============================================================"
echo -e "${GREEN}Teste do SMTP concluído${NC}"
echo "============================================================"
