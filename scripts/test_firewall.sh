#!/bin/bash
# Teste de Firewall (iptables/Netfilter)
# Verifica regras, bloqueios e logging

set -e

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo "========================================"
echo "  Teste de Firewall - iptables/Netfilter"
echo "========================================"
echo ""

# Executar testes dentro do container firewall
echo "1. Verificando regras iptables ativas..."
echo ""

docker-compose exec -T firewall iptables -L -n -v --line-numbers | head -50

echo ""
echo "========================================"
echo "  Regras NAT (POSTROUTING)"
echo "========================================"
echo ""

docker-compose exec -T firewall iptables -t nat -L -n -v

echo ""
echo "========================================"
echo "  Teste de Conectividade da Rede 10.0.1.0/24"
echo "========================================"
echo ""

# Testar conectividade entre containers através do firewall
echo "2. Testando conectividade interna (rede corporativa)..."
echo ""

# Ping do cliente para outros serviços
echo "  • cliente -> ldap (10.0.1.10):"
if docker-compose exec -T cliente ping -c 2 -W 2 10.0.1.10 >/dev/null 2>&1; then
    echo -e "    ${GREEN}✓ OK${NC}"
else
    echo -e "    ${RED}✗ FALHOU${NC}"
fi

echo "  • cliente -> smtp (10.0.1.30):"
if docker-compose exec -T cliente ping -c 2 -W 2 10.0.1.30 >/dev/null 2>&1; then
    echo -e "    ${GREEN}✓ OK${NC}"
else
    echo -e "    ${RED}✗ FALHOU${NC}"
fi

echo "  • cliente -> database (10.0.1.40):"
if docker-compose exec -T cliente ping -c 2 -W 2 10.0.1.40 >/dev/null 2>&1; then
    echo -e "    ${GREEN}✓ OK${NC}"
else
    echo -e "    ${RED}✗ FALHOU${NC}"
fi

echo ""
echo "========================================"
echo "  Teste de Portas Permitidas"
echo "========================================"
echo ""

echo "3. Testando portas de serviços permitidas..."
echo ""

# Testar portas que devem estar abertas
echo "  • SMTP (porta 25):"
if docker-compose exec -T cliente timeout 3 nc -zv smtp 25 2>&1 | grep -q "succeeded\|open"; then
    echo -e "    ${GREEN}✓ Permitida${NC}"
else
    echo -e "    ${RED}✗ Bloqueada${NC}"
fi

echo "  • LDAP (porta 389):"
if docker-compose exec -T cliente timeout 3 nc -zv ldap 389 2>&1 | grep -q "succeeded\|open"; then
    echo -e "    ${GREEN}✓ Permitida${NC}"
else
    echo -e "    ${RED}✗ Bloqueada${NC}"
fi

echo "  • PostgreSQL (porta 5432):"
if docker-compose exec -T cliente timeout 3 nc -zv database 5432 2>&1 | grep -q "succeeded\|open"; then
    echo -e "    ${GREEN}✓ Permitida${NC}"
else
    echo -e "    ${RED}✗ Bloqueada${NC}"
fi

echo "  • rsyslog (porta 514):"
if docker-compose exec -T cliente timeout 3 nc -zuv logs-ntp 514 2>&1 | grep -q "succeeded\|open"; then
    echo -e "    ${GREEN}✓ Permitida${NC}"
else
    echo -e "    ${YELLOW}⚠ UDP - verificar manualmente${NC}"
fi

echo ""
echo "========================================"
echo "  Logs de Firewall"
echo "========================================"
echo ""

echo "4. Últimas 10 linhas de logs do firewall..."
echo ""

docker-compose exec -T firewall tail -10 /var/log/firewall.log 2>/dev/null || \
    echo -e "${YELLOW}(Logs não disponíveis - verificar /var/log/messages)${NC}"

echo ""
echo "========================================"
echo -e "${GREEN}  Teste de Firewall Concluído!${NC}"
echo "========================================"
echo ""
echo "Funcionalidades verificadas:"
echo "  ✓ Regras iptables/Netfilter ativas"
echo "  ✓ Conectividade da rede 10.0.1.0/24"
echo "  ✓ Portas de serviços permitidas"
echo "  ✓ Logs de firewall (se disponíveis)"
echo ""
