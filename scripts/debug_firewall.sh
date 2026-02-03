#!/bin/bash
# Diagnosticar problema do container firewall

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "============================================================"
echo "  DEBUG: Container Firewall"
echo "============================================================"
echo ""

echo "1. Status do container firewall:"
docker-compose ps firewall
echo ""

echo "2. Últimos logs do firewall (últimas 50 linhas):"
docker-compose logs --tail=50 firewall
echo ""

echo "3. Tentando iniciar em modo interativo para debug..."
echo "   (pressione Ctrl+C se travar)"
echo ""

# Parar e remover container
docker-compose stop firewall 2>/dev/null || true
docker-compose rm -f firewall 2>/dev/null || true

# Tentar iniciar manualmente para ver erro
echo "4. Iniciando firewall sem script de forward (teste)..."
docker-compose run --rm --entrypoint /bin/bash firewall -c "
echo 'Container iniciado com sucesso'
echo ''
echo 'Testando comandos do setup_forward.sh...'
echo ''

# Testar se comandos funcionam
echo '1. IP forwarding...'
echo 1 > /proc/sys/net/ipv4/ip_forward 2>&1 || echo 'ERRO: Não conseguiu habilitar IP forward'

echo '2. Limpar NAT...'
iptables -t nat -F 2>&1 || echo 'ERRO: Não conseguiu limpar NAT'

echo '3. Criar regra PREROUTING...'
iptables -t nat -A PREROUTING -p tcp --dport 5432 -j DNAT --to-destination 10.0.1.40:5432 2>&1 || echo 'ERRO: Não conseguiu criar PREROUTING'

echo '4. Listar regras NAT...'
iptables -t nat -L -n -v 2>&1 || echo 'ERRO: Não conseguiu listar NAT'

echo ''
echo 'Diagnóstico concluído!'
"

echo ""
echo "============================================================"
echo "Se viu ERROs acima, o problema está no setup_forward.sh"
echo "============================================================"
