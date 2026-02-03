#!/bin/bash
# Teste do Logs-NTP - Rsyslog + Chrony

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "============================================================"
echo -e "${CYAN}  TESTE: Logs-NTP (Rsyslog + Chrony)${NC}"
echo "============================================================"
echo ""

# 1. Rsyslog
echo -e "${CYAN}1. Verificar rsyslog (porta 514):${NC}"
if docker-compose exec -T logs-ntp ss -ulnp 2>/dev/null | grep -q ":514"; then
    echo -e "${GREEN}✓ rsyslog escutando UDP:514${NC}"
else
    echo -e "${RED}✗ rsyslog não está escutando${NC}"
fi
echo ""

# 2. Estrutura de logs
echo -e "${CYAN}2. Verificar logs remotos:${NC}"
if docker-compose exec -T logs-ntp ls /var/log/remote/ 2>/dev/null | grep -q "."; then
    echo -e "${GREEN}✓ Logs remotos presentes:${NC}"
    docker-compose exec -T logs-ntp ls /var/log/remote/ 2>/dev/null | head -5
else
    echo -e "${RED}✗ Nenhum log remoto ainda${NC}"
fi
echo ""

# 3. NTP
echo -e "${CYAN}3. Verificar NTP (chrony):${NC}"
if docker-compose exec -T logs-ntp chronyc tracking 2>/dev/null | grep -q "Reference ID"; then
    echo -e "${GREEN}✓ Chrony sincronizando${NC}"
    docker-compose exec -T logs-ntp chronyc tracking 2>/dev/null | head -3
else
    echo -e "${RED}✗ Chrony não sincronizando${NC}"
fi
echo ""

echo "============================================================"
echo -e "${GREEN}Teste do Logs-NTP concluído${NC}"
echo "============================================================"
