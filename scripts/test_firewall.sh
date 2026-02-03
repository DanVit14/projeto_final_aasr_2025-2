#!/bin/bash
# Teste do Firewall - Regras e Port Forwarding

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "============================================================"
echo -e "${CYAN}  TESTE: Firewall${NC}"
echo "============================================================"
echo ""

# 1. Regras NAT
echo -e "${CYAN}1. Regras NAT (Port Forwarding):${NC}"
docker-compose exec -T firewall iptables -t nat -L PREROUTING -n -v | head -5
echo ""

# 2. Regras FORWARD
echo -e "${CYAN}2. Regras FORWARD:${NC}"
docker-compose exec -T firewall iptables -L FORWARD -n -v | head -7
echo ""

# 3. Análise
DNAT_PKTS=$(docker-compose exec -T firewall iptables -t nat -L PREROUTING -n -v 2>/dev/null | grep "dpt:5432" | awk '{print $1}' | head -1)
if [ -n "$DNAT_PKTS" ] && [ "$DNAT_PKTS" != "0" ]; then
    echo -e "${GREEN}✓ Firewall processou $DNAT_PKTS pacotes (port forward ativo)${NC}"
else
    echo -e "⚠️  Port forward ainda não processou pacotes (normal antes do teste E2E)"
fi
echo ""

echo "============================================================"
echo -e "${GREEN}Teste do Firewall concluído${NC}"
echo "============================================================"
