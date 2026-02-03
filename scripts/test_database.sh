#!/bin/bash
# Teste do Database - PostgreSQL

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "============================================================"
echo -e "${CYAN}  TESTE: Database (PostgreSQL)${NC}"
echo "============================================================"
echo ""

# 1. PostgreSQL rodando
echo -e "${CYAN}1. Verificar PostgreSQL:${NC}"
if docker-compose exec -T database pg_isready -U postgres 2>/dev/null | grep -q "accepting"; then
    echo -e "${GREEN}✓ PostgreSQL aceitando conexões${NC}"
else
    echo -e "${RED}✗ PostgreSQL não está pronto${NC}"
fi
echo ""

# 2. Conectividade
echo -e "${CYAN}2. Testar conexão:${NC}"
if docker-compose exec -T database psql -U app_user -d empresa_db -c "SELECT 1;" 2>/dev/null | grep -q "1 row"; then
    echo -e "${GREEN}✓ Conexão ao banco OK${NC}"
else
    echo -e "${RED}✗ Erro na conexão${NC}"
fi
echo ""

# 3. Tabelas
echo -e "${CYAN}3. Listar tabelas:${NC}"
docker-compose exec -T database psql -U app_user -d empresa_db -c "\dt" 2>/dev/null || echo "(nenhuma tabela ou erro)"
echo ""

echo "============================================================"
echo -e "${GREEN}Teste do Database concluído${NC}"
echo "============================================================"
