#!/bin/bash
# Teste de NTP (chrony)
# Verifica sincronização de tempo e fontes NTP

set -e

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo "========================================"
echo "  Teste de NTP - Chrony"
echo "========================================"
echo ""

echo "1. Status do serviço chrony..."
echo ""

docker-compose exec -T logs-ntp chronyd -v 2>/dev/null || echo "Chrony versão não disponível"

echo ""
echo "========================================"
echo "  Tracking de Sincronização"
echo "========================================"
echo ""

echo "2. Informações de sincronização (chronyc tracking)..."
echo ""

docker-compose exec -T logs-ntp chronyc tracking 2>/dev/null || \
    echo "Aguardando sincronização inicial..."

echo ""
echo "========================================"
echo "  Fontes NTP"
echo "========================================"
echo ""

echo "3. Servidores NTP configurados (chronyc sources)..."
echo ""

docker-compose exec -T logs-ntp chronyc sources -v 2>/dev/null || \
    docker-compose exec -T logs-ntp chronyc sources 2>/dev/null || \
    echo "Fontes NTP não disponíveis"

echo ""
echo "========================================"
echo "  Estatísticas de Fontes"
echo "========================================"
echo ""

echo "4. Estatísticas detalhadas (chronyc sourcestats)..."
echo ""

docker-compose exec -T logs-ntp chronyc sourcestats 2>/dev/null || \
    echo "Estatísticas não disponíveis (aguardando sincronização)"

echo ""
echo "========================================"
echo "  Teste de Cliente NTP"
echo "========================================"
echo ""

echo "5. Testando consulta NTP do cliente para logs-ntp..."
echo ""

# Tentar consultar o servidor NTP do container logs-ntp
if docker-compose exec -T cliente which ntpdate >/dev/null 2>&1; then
    docker-compose exec -T cliente ntpdate -q logs-ntp 2>/dev/null || \
        echo -e "${YELLOW}Cliente não configurado como cliente NTP${NC}"
else
    echo -e "${YELLOW}ntpdate não instalado no cliente (esperado)${NC}"
fi

echo ""
echo "========================================"
echo -e "${GREEN}  Teste de NTP Concluído!${NC}"
echo "========================================"
echo ""
echo "Notas:"
echo "  • Sincronização NTP pode levar alguns minutos"
echo "  • Chrony escolhe automaticamente a melhor fonte"
echo "  • Offset baixo (<100ms) indica boa sincronização"
echo ""
