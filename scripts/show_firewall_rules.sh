#!/bin/bash
# Mostrar regras do firewall de forma clara

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "============================================================"
echo -e "${CYAN}  Regras do Firewall${NC}"
echo "============================================================"
echo ""

echo -e "${CYAN}1. Regras NAT (PREROUTING - Port Forwarding):${NC}"
echo ""
docker-compose exec -T firewall iptables -t nat -L PREROUTING -n -v --line-numbers 2>/dev/null || {
    echo -e "${YELLOW}⚠ Não foi possível listar regras NAT${NC}"
    echo "  Tente: docker-compose exec firewall iptables -t nat -L PREROUTING -n -v"
}
echo ""

echo -e "${CYAN}2. Regras NAT (POSTROUTING - Masquerade):${NC}"
echo ""
docker-compose exec -T firewall iptables -t nat -L POSTROUTING -n -v --line-numbers 2>/dev/null || {
    echo -e "${YELLOW}⚠ Não foi possível listar regras NAT${NC}"
}
echo ""

echo -e "${CYAN}3. Regras FORWARD (Tráfego atravessando firewall):${NC}"
echo ""
docker-compose exec -T firewall iptables -L FORWARD -n -v --line-numbers 2>/dev/null || {
    echo -e "${YELLOW}⚠ Não foi possível listar regras FORWARD${NC}"
}
echo ""

echo -e "${CYAN}4. Resumo das Regras Principais:${NC}"
echo ""
echo "Procurando por porta 5432 (PostgreSQL)..."
docker-compose exec -T firewall iptables -t nat -L -n -v 2>/dev/null | grep -i "5432\|dpt:5432\|to:10.0.1.40" || {
    echo -e "${YELLOW}  Nenhuma regra encontrada para porta 5432${NC}"
}
echo ""

echo "============================================================"
echo -e "${GREEN}Para executar manualmente:${NC}"
echo ""
echo "  # Ver NAT PREROUTING (port forward)"
echo "  docker-compose exec firewall iptables -t nat -L PREROUTING -n -v"
echo ""
echo "  # Ver todas as regras NAT"
echo "  docker-compose exec firewall iptables -t nat -L -n -v"
echo ""
echo "  # Ver regras FORWARD"
echo "  docker-compose exec firewall iptables -L FORWARD -n -v"
echo ""
echo "  # Ver TODAS as regras"
echo "  docker-compose exec firewall iptables -L -n -v"
echo ""
