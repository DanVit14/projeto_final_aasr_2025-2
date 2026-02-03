#!/bin/bash
# Diagnóstico de rsyslog centralizado
# Verifica se logs estão sendo enviados do SMTP para logs-ntp

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "============================================================"
echo -e "${CYAN}  DIAGNÓSTICO: rsyslog Centralizado${NC}"
echo "============================================================"
echo ""

# ============================================
# 1. Verificar rsyslog no SMTP
# ============================================
echo -e "${CYAN}1. Verificar rsyslog no container SMTP...${NC}"
echo ""

echo "1.1. rsyslog está rodando no SMTP?"
if docker-compose exec -T smtp ps aux | grep -q "[r]syslogd"; then
    echo -e "${GREEN}✓ rsyslog rodando no SMTP${NC}"
else
    echo -e "${RED}✗ rsyslog NÃO está rodando no SMTP${NC}"
fi
echo ""

echo "1.2. Configuração de forward no SMTP:"
echo "Procurando por configurações de rsyslog..."
docker-compose exec -T smtp find /etc/rsyslog* -type f 2>/dev/null | head -10
echo ""

echo "1.3. Conteúdo de rsyslog.conf no SMTP:"
docker-compose exec -T smtp cat /etc/rsyslog.conf 2>/dev/null | grep -v "^#" | grep -v "^$" | head -20
echo ""

echo "1.4. Arquivos em rsyslog.d no SMTP:"
docker-compose exec -T smtp ls -la /etc/rsyslog.d/ 2>/dev/null || echo "  (diretório não existe)"
echo ""

# ============================================
# 2. Verificar rsyslog no Logs-NTP
# ============================================
echo -e "${CYAN}2. Verificar rsyslog no servidor Logs-NTP...${NC}"
echo ""

echo "2.1. rsyslog está rodando no Logs-NTP?"
if docker-compose exec -T logs-ntp ps aux | grep -q "[r]syslogd"; then
    echo -e "${GREEN}✓ rsyslog rodando no Logs-NTP${NC}"
else
    echo -e "${RED}✗ rsyslog NÃO está rodando no Logs-NTP${NC}"
fi
echo ""

echo "2.2. rsyslog está escutando na porta 514?"
if docker-compose exec -T logs-ntp ss -ulnp 2>/dev/null | grep -q ":514"; then
    echo -e "${GREEN}✓ rsyslog escutando em UDP 514${NC}"
    docker-compose exec -T logs-ntp ss -ulnp 2>/dev/null | grep ":514"
else
    echo -e "${RED}✗ rsyslog NÃO está escutando em UDP 514${NC}"
fi
echo ""

echo "2.3. Configuração no Logs-NTP:"
docker-compose exec -T logs-ntp cat /etc/rsyslog.conf 2>/dev/null | grep -E "514|UDP|ModLoad.*imudp" | head -10
echo ""

# ============================================
# 3. Testar Conectividade
# ============================================
echo -e "${CYAN}3. Testar conectividade SMTP → Logs-NTP...${NC}"
echo ""

echo "3.1. SMTP consegue resolver 'logs-ntp'?"
if docker-compose exec -T smtp ping -c 2 logs-ntp >/dev/null 2>&1; then
    echo -e "${GREEN}✓ SMTP consegue alcançar logs-ntp${NC}"
else
    echo -e "${RED}✗ SMTP não consegue alcançar logs-ntp${NC}"
fi
echo ""

echo "3.2. Porta 514 UDP acessível?"
if docker-compose exec -T smtp timeout 2 nc -zuv logs-ntp 514 2>&1 | grep -q "succeeded\|open"; then
    echo -e "${GREEN}✓ Porta 514 UDP acessível${NC}"
else
    echo -e "${YELLOW}⚠ nc pode não suportar UDP ou porta não acessível${NC}"
fi
echo ""

# ============================================
# 4. Verificar Logs Existentes
# ============================================
echo -e "${CYAN}4. Procurar logs no servidor Logs-NTP...${NC}"
echo ""

echo "4.1. Estrutura de /var/log no Logs-NTP:"
docker-compose exec -T logs-ntp ls -la /var/log/ 2>/dev/null | head -15
echo ""

echo "4.2. Procurar diretórios de logs remotos:"
docker-compose exec -T logs-ntp find /var/log -type d -name "*remote*" -o -name "*host*" 2>/dev/null || echo "  (nenhum diretório remoto encontrado)"
echo ""

echo "4.3. Procurar logs do SMTP/Postfix:"
docker-compose exec -T logs-ntp find /var/log -name "*mail*" -o -name "*postfix*" 2>/dev/null || echo "  (nenhum log mail/postfix encontrado)"
echo ""

echo "4.4. Últimas 10 linhas de messages:"
docker-compose exec -T logs-ntp tail -10 /var/log/messages 2>/dev/null || echo "  (/var/log/messages não existe)"
echo ""

echo "4.5. Últimas 10 linhas de syslog:"
docker-compose exec -T logs-ntp tail -10 /var/log/syslog 2>/dev/null || echo "  (/var/log/syslog não existe)"
echo ""

# ============================================
# 5. Teste de Envio Manual
# ============================================
echo -e "${CYAN}5. Teste de envio manual de log...${NC}"
echo ""

TEST_MSG="DIAGNOSE_RSYSLOG_$(date +%s)"
echo "5.1. Enviando mensagem de teste do SMTP: ${TEST_MSG}"
docker-compose exec -T smtp logger -n logs-ntp -P 514 "${TEST_MSG}" 2>/dev/null || echo "  (logger pode não estar disponível)"
echo "Aguardando 3 segundos..."
sleep 3
echo ""

echo "5.2. Procurando mensagem no Logs-NTP..."
if docker-compose exec -T logs-ntp grep -r "${TEST_MSG}" /var/log 2>/dev/null; then
    echo -e "${GREEN}✓ Mensagem de teste ENCONTRADA!${NC}"
else
    echo -e "${RED}✗ Mensagem de teste NÃO encontrada${NC}"
fi
echo ""

# ============================================
# RESUMO
# ============================================
echo "============================================================"
echo -e "${CYAN}  RESUMO DO DIAGNÓSTICO${NC}"
echo "============================================================"
echo ""
echo "Próximos passos sugeridos:"
echo "  1. Se rsyslog não está rodando → iniciar rsyslog"
echo "  2. Se porta 514 não escuta → configurar rsyslog para receber UDP"
echo "  3. Se conectividade falha → verificar rede Docker"
echo "  4. Se logs não aparecem → configurar forward no SMTP"
echo ""
echo "Execute o script de correção:"
echo "  ./scripts/fix_rsyslog.sh"
echo ""
