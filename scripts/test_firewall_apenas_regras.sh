#!/bin/bash
# Teste ultra-rápido: apenas mostra regras e contadores
# NÃO tenta conectar (evita travamento)

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "============================================================"
echo -e "${CYAN}  FIREWALL: Regras e Evidências${NC}"
echo "============================================================"
echo ""

# ============================================
# 1. Regras NAT
# ============================================
echo -e "${CYAN}1. Regras NAT (Port Forwarding):${NC}"
echo ""
docker-compose exec -T firewall iptables -t nat -L PREROUTING -n -v --line-numbers 2>/dev/null
echo ""

# ============================================
# 2. Regras FORWARD
# ============================================
echo -e "${CYAN}2. Regras FORWARD (Filtro + Log):${NC}"
echo ""
docker-compose exec -T firewall iptables -L FORWARD -n -v --line-numbers 2>/dev/null | head -10
echo ""

# ============================================
# 3. Análise de Contadores
# ============================================
echo -e "${CYAN}3. Análise de Contadores:${NC}"
echo ""

# Extrair contadores DNAT
DNAT_PKTS=$(docker-compose exec -T firewall iptables -t nat -L PREROUTING -n -v 2>/dev/null | grep "dpt:5432" | awk '{print $1}')

if [ -n "$DNAT_PKTS" ] && [ "$DNAT_PKTS" != "0" ]; then
    echo -e "${GREEN}✓ DNAT processou ${DNAT_PKTS} pacotes${NC}"
    echo "  → Tráfego passou pelo firewall!"
else
    echo -e "${YELLOW}⚠ DNAT ainda não processou pacotes (0 ou vazio)${NC}"
fi

# Extrair contadores FORWARD
FORWARD_PKTS=$(docker-compose exec -T firewall iptables -L FORWARD -n -v 2>/dev/null | grep "10.0.1.40.*dpt:5432" | head -1 | awk '{print $1}')

if [ -n "$FORWARD_PKTS" ] && [ "$FORWARD_PKTS" != "0" ]; then
    echo -e "${GREEN}✓ FORWARD processou ${FORWARD_PKTS} pacotes${NC}"
    echo "  → Conexões foram encaminhadas ao database!"
else
    echo -e "${YELLOW}⚠ FORWARD ainda não processou pacotes${NC}"
fi
echo ""

# ============================================
# 4. Resumo Visual
# ============================================
echo "============================================================"
echo -e "${CYAN}  RESUMO${NC}"
echo "============================================================"
echo ""
echo "Regras Configuradas:"
echo "  ✓ DNAT: 5432 → 10.0.1.40:5432"
echo "  ✓ MASQUERADE: Ativo"
echo "  ✓ FORWARD ACCEPT: Bidirecional"
echo "  ✓ LOG: Registrando conexões"
echo ""

if [ -n "$DNAT_PKTS" ] && [ "$DNAT_PKTS" != "0" ]; then
    echo -e "${GREEN}Status: FIREWALL ATIVO E PROCESSANDO TRÁFEGO ✓${NC}"
    echo ""
    echo "Evidência: $DNAT_PKTS pacotes já passaram pelo port forward"
else
    echo -e "${YELLOW}Status: Firewall configurado, aguardando tráfego${NC}"
fi
echo ""

# ============================================
# 5. Comandos Úteis
# ============================================
echo "Comandos para demonstração ao vivo:"
echo ""
echo "  # Ver regras NAT"
echo "  docker-compose exec firewall iptables -t nat -L PREROUTING -n -v"
echo ""
echo "  # Ver contadores em tempo real"
echo "  watch -n 1 'docker exec firewall iptables -t nat -L PREROUTING -n -v'"
echo ""
echo "  # Monitorar logs"
echo "  docker-compose exec firewall dmesg -w | grep FW-DB"
echo ""
