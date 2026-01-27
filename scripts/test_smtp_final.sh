#!/bin/bash
# Script final para testar se o Postfix está funcionando

set +e

echo "=========================================="
echo "Teste Final do Postfix SMTP"
echo "=========================================="
echo ""

# 1. Verificar se o Postfix está rodando
echo "1. Status do Postfix:"
docker-compose exec smtp postfix status 2>&1 | grep -E "running|not running" || docker-compose exec smtp postfix status 2>&1 | tail -1
echo ""

# 2. Teste básico de conexão
echo "2. Teste básico (QUIT):"
RESPONSE1=$(echo "QUIT" | timeout 5 docker-compose exec -T smtp nc localhost 25 2>&1)
if echo "$RESPONSE1" | grep -q "220"; then
    echo -e "\033[0;32m✓ SUCESSO - Postfix está respondendo!\033[0m"
    echo "$RESPONSE1" | head -1
else
    echo -e "\033[1;31m✗ FALHOU - Postfix não respondeu\033[0m"
    echo "   Resposta recebida: $RESPONSE1"
fi
echo ""

# 3. Teste completo com EHLO
echo "3. Teste completo (EHLO + QUIT):"
RESPONSE2=$(echo -e "EHLO test.local\nQUIT" | timeout 5 docker-compose exec -T smtp nc localhost 25 2>&1)
if echo "$RESPONSE2" | grep -q "250"; then
    echo -e "\033[0;32m✓ SUCESSO - Postfix respondeu ao EHLO!\033[0m"
    echo "$RESPONSE2" | head -3 | sed 's/^/   /'
else
    echo -e "\033[1;33m⚠ Resposta inesperada\033[0m"
    echo "$RESPONSE2" | head -5 | sed 's/^/   /'
fi
echo ""

# 4. Verificar processos smtpd
echo "4. Processos smtpd ativos:"
SMTPD_COUNT=$(docker-compose exec smtp ps aux | grep -c "smtpd.*smtp" || echo "0")
if [ "$SMTPD_COUNT" -gt "0" ]; then
    echo -e "\033[0;32m✓ $SMTPD_COUNT processo(s) smtpd rodando\033[0m"
    docker-compose exec smtp ps aux | grep "smtpd.*smtp" | grep -v grep | head -2
else
    echo -e "\033[1;33m⚠ Nenhum smtpd rodando (pode iniciar sob demanda)\033[0m"
fi
echo ""

# 5. Teste do host (porta exposta)
echo "5. Teste do host (porta 25 exposta):"
if command -v nc >/dev/null 2>&1; then
    HOST_RESPONSE=$(echo "QUIT" | timeout 3 nc localhost 25 2>&1)
    if echo "$HOST_RESPONSE" | grep -q "220"; then
        echo -e "\033[0;32m✓ Postfix acessível do host!\033[0m"
        echo "$HOST_RESPONSE" | head -1
    else
        echo -e "\033[1;33m⚠ Não conseguiu conectar do host\033[0m"
    fi
else
    echo "   nc não está instalado no host (normal)"
fi
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
echo ""
if echo "$RESPONSE1" | grep -q "220"; then
    echo -e "\033[0;32m✓✓✓ Postfix está FUNCIONANDO! ✓✓✓\033[0m"
    echo ""
    echo "Próximos passos:"
    echo "  1. Testar envio de e-mail: docker-compose exec smtp mail -s 'Teste' user1@empresa.local < /dev/null"
    echo "  2. Reativar Amavis quando quiser (descomentar content_filter no main.cf)"
    echo "  3. Implementar outros containers (Firewall, Cliente)"
else
    echo -e "\033[1;31m✗ Postfix ainda não está respondendo corretamente\033[0m"
    echo ""
    echo "Verificar:"
    echo "  - docker-compose logs smtp | tail -50"
    echo "  - docker-compose exec smtp postfix status"
fi
