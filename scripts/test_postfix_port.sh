#!/bin/bash
# Script para testar se o Postfix está escutando na porta 25

set +e

echo "=========================================="
echo "Testando Porta 25 do Postfix"
echo "=========================================="
echo ""

# 1. Verificar processos Postfix
echo "1. Processos Postfix:"
docker-compose exec smtp ps aux | grep postfix | grep -v grep
echo ""

# 2. Verificar portas abertas usando ss
echo "2. Portas abertas (ss):"
docker-compose exec smtp ss -tlnp 2>/dev/null | grep -E ":(25|587)" || echo "   Nenhuma porta encontrada ou ss não disponível"
echo ""

# 3. Verificar portas usando netstat
echo "3. Portas abertas (netstat):"
docker-compose exec smtp netstat -tlnp 2>/dev/null | grep -E ":(25|587)" || echo "   Nenhuma porta encontrada ou netstat não disponível"
echo ""

# 4. Testar conexão SMTP usando nc
echo "4. Testando conexão SMTP (nc):"
if docker-compose exec -T smtp which nc >/dev/null 2>&1; then
    SMTP_RESPONSE=$(echo "QUIT" | timeout 3 docker-compose exec -T smtp nc localhost 25 2>&1)
    if echo "$SMTP_RESPONSE" | grep -q "220"; then
        echo -e "\033[0;32m✓ OK - Postfix está respondendo\033[0m"
        echo "$SMTP_RESPONSE" | head -1 | sed 's/^/   /'
    else
        echo -e "\033[1;31m✗ FALHOU - Postfix não está respondendo\033[0m"
        echo "   Resposta: $SMTP_RESPONSE"
    fi
else
    echo "   nc não está disponível"
fi
echo ""

# 5. Testar conexão SMTP usando telnet
echo "5. Testando conexão SMTP (telnet):"
if docker-compose exec -T smtp which telnet >/dev/null 2>&1; then
    SMTP_RESPONSE=$(echo "QUIT" | timeout 3 docker-compose exec -T smtp telnet localhost 25 2>&1 | head -3)
    if echo "$SMTP_RESPONSE" | grep -q "220"; then
        echo -e "\033[0;32m✓ OK - Postfix está respondendo\033[0m"
        echo "$SMTP_RESPONSE" | grep "220" | sed 's/^/   /'
    else
        echo -e "\033[1;33m⚠ Telnet não conseguiu conectar ou resposta inesperada\033[0m"
    fi
else
    echo "   telnet não está disponível"
fi
echo ""

# 6. Testar do host (porta exposta)
echo "6. Testando do host (porta 25 exposta):"
HOST_RESPONSE=$(echo "QUIT" | timeout 3 nc localhost 25 2>&1 | head -1)
if echo "$HOST_RESPONSE" | grep -q "220"; then
    echo -e "\033[0;32m✓ OK - Postfix está acessível do host\033[0m"
    echo "   Resposta: $HOST_RESPONSE"
else
    echo -e "\033[1;33m⚠ Não conseguiu conectar do host\033[0m"
    echo "   (Isso pode ser normal se nc não estiver instalado no host)"
fi
echo ""

# 7. Verificar logs do Postfix para erros de bind
echo "7. Verificando erros de bind nos logs:"
BIND_ERRORS=$(docker-compose logs smtp 2>&1 | grep -iE "bind.*25|address.*already.*use|cannot.*bind|port.*25" | tail -5)
if [ -z "$BIND_ERRORS" ]; then
    echo -e "\033[0;32m✓ Nenhum erro de bind encontrado\033[0m"
else
    echo -e "\033[1;31m✗ Erros de bind encontrados:\033[0m"
    echo "$BIND_ERRORS" | sed 's/^/   /'
fi
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
