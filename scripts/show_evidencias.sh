#!/bin/bash
# Mostrar evidências do sistema em funcionamento
# Útil para apresentação e demonstração

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "============================================================"
echo -e "${CYAN}  EVIDÊNCIAS DO SISTEMA - Projeto AASR 2025${NC}"
echo "============================================================"
echo ""

# 1. Status dos containers
echo -e "${CYAN}1. Status dos Containers:${NC}"
docker-compose ps
echo ""

# 2. Auditoria no banco de dados
echo "============================================================"
echo -e "${CYAN}2. Registros de Auditoria (últimos 5):${NC}"
echo "============================================================"
docker-compose exec -T database psql -U app_user -d empresa_db -c "SELECT * FROM audit_log ORDER BY timestamp DESC LIMIT 5;"
echo ""

# 3. Logs centralizados
echo "============================================================"
echo -e "${CYAN}3. Logs Centralizados (Rsyslog):${NC}"
echo "============================================================"
echo -e "${YELLOW}Hosts que enviaram logs:${NC}"
docker-compose exec -T logs-ntp ls -lh /var/log/remote/
echo ""

# 4. Regras do firewall
echo "============================================================"
echo -e "${CYAN}4. Firewall - Regras NAT (Port Forwarding):${NC}"
echo "============================================================"
docker-compose exec -T firewall iptables -t nat -L -n -v
echo ""

# 5. Usuários LDAP
echo "============================================================"
echo -e "${CYAN}5. Usuários no LDAP (Samba AD DC):${NC}"
echo "============================================================"
docker-compose exec -T ldap samba-tool user list 2>/dev/null
echo ""

# 6. Sincronização NTP
echo "============================================================"
echo -e "${CYAN}6. Sincronização de Tempo (Chrony):${NC}"
echo "============================================================"
docker-compose exec -T logs-ntp chronyc tracking
echo ""

# 7. Estatísticas finais
echo "============================================================"
echo -e "${GREEN}  RESUMO DO SISTEMA${NC}"
echo "============================================================"
echo ""

# Contar registros de auditoria
AUDIT_COUNT=$(docker-compose exec -T database psql -U app_user -d empresa_db -t -c "SELECT COUNT(*) FROM audit_log;" 2>/dev/null | tr -d ' ')
echo -e "  ${GREEN}✓${NC} Registros de auditoria: ${CYAN}${AUDIT_COUNT}${NC}"

# Contar usuários LDAP
USER_COUNT=$(docker-compose exec -T ldap samba-tool user list 2>/dev/null | wc -l)
echo -e "  ${GREEN}✓${NC} Usuários no LDAP: ${CYAN}${USER_COUNT}${NC}"

# Contar hosts enviando logs
LOG_HOSTS=$(docker-compose exec -T logs-ntp ls /var/log/remote/ 2>/dev/null | wc -l)
echo -e "  ${GREEN}✓${NC} Hosts enviando logs: ${CYAN}${LOG_HOSTS}${NC}"

# Verificar regras de firewall
FW_RULES=$(docker-compose exec -T firewall iptables -t nat -L PREROUTING -n 2>/dev/null | grep -c "DNAT" || echo "0")
echo -e "  ${GREEN}✓${NC} Regras NAT no firewall: ${CYAN}${FW_RULES}${NC}"

echo ""
echo "============================================================"
echo -e "${GREEN}  Sistema operacional e integrado!${NC}"
echo "============================================================"
