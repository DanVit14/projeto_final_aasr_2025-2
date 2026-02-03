#!/bin/bash
# Teste simples e rápido do firewall (sem psql)
# Foca em conectividade TCP e evidências visuais

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "============================================================"
echo -e "${CYAN}  TESTE RÁPIDO: Firewall Port Forwarding${NC}"
echo "============================================================"
echo ""
echo "Cenário: Cliente → Firewall:5432 → Database:5432"
echo ""

# ============================================
# PASSO 1: Verificar Regras
# ============================================
echo -e "${CYAN}PASSO 1: Verificar regras do firewall...${NC}"
echo ""

echo "1.1. Regras NAT (DNAT - Port Forwarding):"
docker-compose exec -T firewall iptables -t nat -L PREROUTING -n -v 2>/dev/null | head -5
echo ""

echo "1.2. Regras FORWARD (Filtro + Log):"
docker-compose exec -T firewall iptables -L FORWARD -n -v 2>/dev/null | head -7
echo ""

# ============================================
# PASSO 2: Testar Conectividade Direta
# ============================================
echo -e "${CYAN}PASSO 2: Testar conectividade DIRETA (Cliente → Database)...${NC}"
echo ""

if timeout 3 docker-compose exec -T cliente bash -c '</dev/tcp/10.0.1.40/5432' 2>/dev/null; then
    echo -e "${GREEN}✓ Conexão direta funciona (10.0.1.40:5432)${NC}"
else
    echo -e "${RED}✗ Conexão direta falhou${NC}"
fi
echo ""

# ============================================
# PASSO 3: Testar Conectividade via Firewall
# ============================================
echo -e "${CYAN}PASSO 3: Testar conectividade VIA FIREWALL (Cliente → Firewall → Database)...${NC}"
echo ""

if timeout 3 docker-compose exec -T cliente bash -c '</dev/tcp/10.0.1.20/5432' 2>/dev/null; then
    echo -e "${GREEN}✓ Conexão via firewall funciona (10.0.1.20:5432)${NC}"
    echo -e "${GREEN}  → Port forwarding ativo!${NC}"
else
    echo -e "${RED}✗ Conexão via firewall falhou${NC}"
    echo -e "${YELLOW}  → Port forwarding pode não estar configurado${NC}"
fi
echo ""

# ============================================
# PASSO 4: Múltiplas Conexões (Gerar Logs)
# ============================================
echo -e "${CYAN}PASSO 4: Gerar múltiplas conexões para logs...${NC}"
echo ""

echo "4.1. Executando 5 conexões via firewall..."
for i in {1..5}; do
    timeout 1 docker-compose exec -T cliente bash -c '</dev/tcp/10.0.1.20/5432' 2>/dev/null && echo "  Conexão $i: OK" || echo "  Conexão $i: falhou"
done
echo ""

# ============================================
# PASSO 5: Verificar Logs do Firewall
# ============================================
echo -e "${CYAN}PASSO 5: Verificar logs do firewall...${NC}"
echo ""

echo "5.1. Logs do kernel (últimos 10 registros [FW-DB]):"
if docker-compose exec -T firewall dmesg 2>/dev/null | grep "FW-DB" | tail -10; then
    echo ""
    echo -e "${GREEN}✓ Firewall registrou conexões nos logs${NC}"
else
    echo -e "${YELLOW}⚠ Nenhum log [FW-DB] encontrado (pode estar em outro local)${NC}"
fi
echo ""

echo "5.2. Últimas linhas do dmesg (todas):"
docker-compose exec -T firewall dmesg 2>/dev/null | tail -5
echo ""

# ============================================
# PASSO 6: Contadores de Pacotes
# ============================================
echo -e "${CYAN}PASSO 6: Verificar contadores de pacotes...${NC}"
echo ""

echo "6.1. Contadores NAT (quantos pacotes passaram):"
docker-compose exec -T firewall iptables -t nat -L PREROUTING -n -v 2>/dev/null | grep "5432\|pkts" | head -3
echo ""

echo "6.2. Contadores FORWARD:"
docker-compose exec -T firewall iptables -L FORWARD -n -v 2>/dev/null | grep -E "5432|10.0.1.40|pkts" | head -5
echo ""

# ============================================
# RESUMO
# ============================================
echo "============================================================"
echo -e "${GREEN}  RESUMO DO TESTE${NC}"
echo "============================================================"
echo ""
echo "Evidências coletadas:"
echo "  ✓ Regras iptables (NAT + FORWARD)"
echo "  ✓ Conectividade TCP via firewall"
echo "  ✓ Logs do firewall (se disponíveis)"
echo "  ✓ Contadores de pacotes"
echo ""
echo "Para demonstração:"
echo "  1. Mostrar regras: docker-compose exec firewall iptables -t nat -L -n -v"
echo "  2. Testar ao vivo: docker-compose exec cliente bash -c '</dev/tcp/10.0.1.20/5432'"
echo "  3. Ver logs: docker-compose exec firewall dmesg | grep FW-DB"
echo ""
echo "Arquivos de evidência:"
echo "  - docs/GUIA_TESTE_E2E.md (topologia e explicação)"
echo "  - docs/FIREWALL_INTEGRACAO.md (documentação técnica)"
echo "  - docs/RESUMO_FIREWALL.md (resumo executivo)"
echo ""
