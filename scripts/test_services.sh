#!/bin/bash
# Script de testes dos serviços

set -e

echo "=========================================="
echo "Testes dos Serviços - Projeto AASR"
echo "=========================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_service() {
    local name=$1
    local host=$2
    local port=$3
    local protocol=${4:-tcp}
    
    echo -n "Testando $name ($host:$port)... "
    
    if [ "$protocol" = "udp" ]; then
        timeout 2 bash -c "echo > /dev/$protocol/$host/$port" 2>/dev/null && echo -e "${GREEN}OK${NC}" || echo -e "${RED}FALHOU${NC}"
    else
        timeout 2 bash -c "cat < /dev/null > /dev/$protocol/$host/$port" 2>/dev/null && echo -e "${GREEN}OK${NC}" || echo -e "${RED}FALHOU${NC}"
    fi
}

# Teste 1: NTP
echo "1. Testando NTP (logs-ntp:123)..."
chronyd -q -t 1 2>/dev/null && echo -e "${GREEN}OK${NC}" || echo -e "${YELLOW}Verificar manualmente${NC}"
echo ""

# Teste 2: LDAP
echo "2. Testando LDAP (ldap:389)..."
ldapsearch -x -H ldap://ldap -b "dc=empresa,dc=local" 2>/dev/null | head -1 && echo -e "${GREEN}OK${NC}" || echo -e "${RED}FALHOU${NC}"
echo ""

# Teste 3: PostgreSQL
echo "3. Testando PostgreSQL (database:5432)..."
PGPASSWORD=db_pass_123 psql -h database -U app_user -d empresa_db -c "SELECT 1;" 2>/dev/null && echo -e "${GREEN}OK${NC}" || echo -e "${RED}FALHOU${NC}"
echo ""

# Teste 4: SMTP (banner 220; timeout 15s para dar tempo ao Postfix responder)
echo "4. Testando SMTP (smtp:25)..."
smtp_ok=0
# Usar timeout maior e aguardar resposta do Postfix (pode demorar se estiver ocupado com Amavis/ClamAV)
if (echo "QUIT" | timeout 15 nc -w 12 smtp 25 2>/dev/null || true) | head -10 | grep -q "220"; then
  smtp_ok=1
fi
[ "$smtp_ok" -eq 1 ] && echo -e "${GREEN}OK${NC}" || echo -e "${RED}FALHOU${NC}"
echo ""

# Teste 5: rsyslog
echo "5. Testando rsyslog (logs-ntp:514)..."
logger -n logs-ntp -P 514 "Teste de log" 2>/dev/null && echo -e "${GREEN}OK${NC}" || echo -e "${YELLOW}Verificar manualmente${NC}"
echo ""

# Teste 6: SMB/CIFS
echo "6. Testando SMB/CIFS (ldap:445)..."
timeout 2 bash -c "cat < /dev/null > /dev/tcp/ldap/445" 2>/dev/null && echo -e "${GREEN}OK${NC}" || echo -e "${YELLOW}Verificar manualmente${NC}"
echo ""

echo "=========================================="
echo "Testes concluídos!"
echo "=========================================="
