#!/bin/bash
# Executar todos os testes (individuais + E2E)

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "============================================================"
echo -e "${CYAN}  EXECUTANDO TODOS OS TESTES${NC}"
echo "============================================================"
echo ""

# Testes individuais
echo ">> Testando Firewall..."
./scripts/test_firewall.sh
echo ""

echo ">> Testando LDAP..."
./scripts/test_ldap.sh
echo ""

echo ">> Testando SMTP..."
./scripts/test_smtp.sh
echo ""

echo ">> Testando Database..."
./scripts/test_database.sh
echo ""

echo ">> Testando Logs-NTP..."
./scripts/test_logs_ntp.sh
echo ""

# Teste E2E
echo ">> Testando Integração End-to-End..."
./scripts/test_end_to_end.sh
echo ""

echo "============================================================"
echo -e "${GREEN}  TODOS OS TESTES CONCLUÍDOS${NC}"
echo "============================================================"
