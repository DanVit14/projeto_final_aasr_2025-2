#!/bin/bash
# Script Master - Executa todos os testes do projeto
# Gera evidências para apresentação

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

echo "========================================"
echo -e "${BLUE}  TESTES COMPLETOS - AASR 2025-2${NC}"
echo "========================================"
echo ""
echo "Projeto: Infraestrutura Corporativa"
echo "Data: $(date '+%d/%m/%Y %H:%M:%S')"
echo ""

# Garantir que todos os serviços estão rodando
echo -e "${YELLOW}► Iniciando serviços...${NC}"
docker-compose up -d
sleep 5
echo ""

# Teste 1: Serviços Básicos
echo "========================================"
echo -e "${BLUE}  TESTE 1: Serviços Básicos${NC}"
echo "========================================"
echo ""
./scripts/run_test_services.sh
echo ""
sleep 2

# Teste 2: CRUD do Banco de Dados
echo "========================================"
echo -e "${BLUE}  TESTE 2: CRUD - PostgreSQL${NC}"
echo "========================================"
echo ""
./scripts/test_crud_db.sh
echo ""
sleep 2

# Teste 3: Backup do Banco
echo "========================================"
echo -e "${BLUE}  TESTE 3: Backup do Banco de Dados${NC}"
echo "========================================"
echo ""
./scripts/backup_db.sh
echo ""
sleep 2

# Teste 4: ACLs
echo "========================================"
echo -e "${BLUE}  TESTE 4: Permissões Avançadas (ACLs)${NC}"
echo "========================================"
echo ""
chmod +x ./scripts/test_acls.sh
./scripts/test_acls.sh
echo ""
sleep 2

# Teste 5: Firewall
echo "========================================"
echo -e "${BLUE}  TESTE 5: Firewall (iptables/Netfilter)${NC}"
echo "========================================"
echo ""
chmod +x ./scripts/test_firewall.sh
./scripts/test_firewall.sh
echo ""
sleep 2

# Teste 6: NTP
echo "========================================"
echo -e "${BLUE}  TESTE 6: NTP (Chrony)${NC}"
echo "========================================"
echo ""
chmod +x ./scripts/test_ntp.sh
./scripts/test_ntp.sh
echo ""
sleep 2

# Teste 7: SMTP Completo
echo "========================================"
echo -e "${BLUE}  TESTE 7: SMTP - Envio e Entrega${NC}"
echo "========================================"
echo ""
./scripts/test_smtp_completo.sh
echo ""
sleep 2

# Teste 8: Integrações Entre Serviços
echo "========================================"
echo -e "${BLUE}  TESTE 8: Integrações Entre Serviços${NC}"
echo "========================================"
echo ""
./scripts/test_integrations.sh
echo ""

# Resumo final
echo ""
echo "========================================"
echo -e "${GREEN}  TODOS OS TESTES CONCLUÍDOS!${NC}"
echo "========================================"
echo ""
echo "Testes executados:"
echo "  ✓ Conectividade de serviços (LDAP, DB, SMTP, rsyslog, SMB)"
echo "  ✓ CRUD no PostgreSQL"
echo "  ✓ Backup do banco de dados"
echo "  ✓ ACLs (permissões avançadas)"
echo "  ✓ Firewall (iptables/Netfilter)"
echo "  ✓ NTP (sincronização de tempo)"
echo "  ✓ SMTP (envio e entrega de email)"
echo "  ✓ Integrações entre serviços (SMTP-LDAP, rsyslog, NTP)"
echo ""
echo "Próximos passos:"
echo "  1. Testar restore do backup:"
echo "     ./scripts/restore_db.sh backups/backup_YYYYMMDD_HHMMSS.sql.gz"
echo ""
echo "  2. Ver documentação em docs/"
echo ""
