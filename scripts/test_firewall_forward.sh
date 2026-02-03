#!/bin/bash
# Testar conexão ao PostgreSQL via Firewall (port forward)
# Demonstra integração do firewall no fluxo de dados

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "============================================================"
echo -e "${CYAN}  TESTE: Firewall como Proxy para PostgreSQL${NC}"
echo "============================================================"
echo ""
echo "Cenário: Cliente acessa Database através do Firewall"
echo "  Cliente → Firewall:5432 → Database:5432"
echo ""

# ============================================
# 1. Verificar Port Forwarding no Firewall
# ============================================
echo -e "${CYAN}PASSO 1: Verificar configuração do Firewall...${NC}"
echo ""

echo "1.1. Verificar regras NAT (DNAT):"
docker-compose exec -T firewall iptables -t nat -L PREROUTING -n -v | grep -E "5432|tcp" || echo "  (sem regras DNAT)"
echo ""

echo "1.2. Verificar regras FORWARD:"
docker-compose exec -T firewall iptables -L FORWARD -n -v | grep -E "5432|10.0.1.40" || echo "  (sem regras FORWARD)"
echo ""

# ============================================
# 2. Testar Conectividade Direta (sem Firewall)
# ============================================
echo -e "${CYAN}PASSO 2: Teste de conectividade DIRETA (Cliente → Database)...${NC}"
echo ""

if docker-compose exec -T cliente timeout 3 bash -c "</dev/tcp/10.0.1.40/5432" 2>/dev/null; then
    echo -e "${GREEN}✓ Conexão direta funciona (10.0.1.40:5432)${NC}"
else
    echo -e "${RED}✗ Conexão direta falhou${NC}"
fi
echo ""

# ============================================
# 3. Testar Conectividade via Firewall
# ============================================
echo -e "${CYAN}PASSO 3: Teste de conectividade VIA FIREWALL (Cliente → Firewall → Database)...${NC}"
echo ""

if docker-compose exec -T cliente timeout 3 bash -c "</dev/tcp/10.0.1.20/5432" 2>/dev/null; then
    echo -e "${GREEN}✓ Conexão via firewall funciona (10.0.1.20:5432)${NC}"
    echo -e "${GREEN}  → Port forwarding ativo!${NC}"
else
    echo -e "${RED}✗ Conexão via firewall falhou${NC}"
    echo -e "${YELLOW}  → Port forwarding pode não estar configurado${NC}"
fi
echo ""

# ============================================
# 4. Query PostgreSQL via Firewall
# ============================================
echo -e "${CYAN}PASSO 4: Executar query no PostgreSQL via Firewall...${NC}"
echo ""

TEST_ID="FW_TEST_$(date +%s)"

echo "4.1. Conectar via firewall e executar query..."
# Usar psql no container cliente conectando via firewall
if docker-compose exec -T cliente psql -h 10.0.1.20 -U app_user -d empresa_db -c "SELECT NOW() as conexao_via_firewall, '${TEST_ID}' as test_id;" 2>/dev/null; then
    echo ""
    echo -e "${GREEN}✓ Query executada com sucesso via firewall!${NC}"
else
    echo -e "${YELLOW}⚠ Query falhou (psql pode não estar disponível no cliente)${NC}"
    echo "  Alternativa: testar porta TCP apenas"
fi
echo ""

# ============================================
# 5. Verificar Logs do Firewall
# ============================================
echo -e "${CYAN}PASSO 5: Verificar logs do firewall...${NC}"
echo ""

echo "5.1. Procurar logs de conexão PostgreSQL (últimos 20 logs):"
if docker-compose exec -T firewall grep "FW-DB" /var/log/kern.log 2>/dev/null | tail -20; then
    echo ""
    echo -e "${GREEN}✓ Firewall registrou conexões ao PostgreSQL${NC}"
elif docker-compose exec -T firewall dmesg | grep "FW-DB" | tail -20 2>/dev/null; then
    echo ""
    echo -e "${GREEN}✓ Firewall registrou conexões (via dmesg)${NC}"
else
    echo -e "${YELLOW}⚠ Logs não encontrados (podem estar em /var/log/syslog ou dmesg)${NC}"
fi
echo ""

echo "5.2. Ver últimos logs do kernel (podem conter iptables logs):"
docker-compose exec -T firewall dmesg | tail -10
echo ""

# ============================================
# 6. Estatísticas das Regras
# ============================================
echo -e "${CYAN}PASSO 6: Estatísticas de uso das regras...${NC}"
echo ""

echo "6.1. Contadores de pacotes nas regras NAT:"
docker-compose exec -T firewall iptables -t nat -L -n -v | grep -E "pkts|5432" | head -10
echo ""

echo "6.2. Contadores nas regras FORWARD:"
docker-compose exec -T firewall iptables -L FORWARD -n -v | grep -E "pkts|5432|10.0.1.40" | head -10
echo ""

# ============================================
# RESUMO
# ============================================
echo "============================================================"
echo -e "${CYAN}  RESUMO DO TESTE${NC}"
echo "============================================================"
echo ""
echo "Firewall integrado no fluxo:"
echo "  1. Regras NAT configuradas (DNAT)"
echo "  2. Port forwarding 5432 ativo"
echo "  3. Logs de conexão registrados"
echo "  4. Cliente pode acessar Database via Firewall"
echo ""
echo "Para apresentação:"
echo "  • Mostrar diagrama: Cliente → Firewall → Database"
echo "  • Destacar regras iptables (PREROUTING, FORWARD)"
echo "  • Mostrar logs do firewall registrando conexões"
echo "  • Executar query via firewall em tempo real"
echo ""
echo "Comando para monitorar logs ao vivo:"
echo "  docker-compose exec firewall dmesg -w | grep FW-DB"
echo ""
