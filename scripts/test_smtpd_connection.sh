#!/bin/bash
# Script para testar se o smtpd inicia quando há conexão

set +e

echo "=========================================="
echo "Testando se smtpd inicia com conexão"
echo "=========================================="
echo ""

# 1. Ver processos antes da conexão
echo "1. Processos smtpd ANTES da conexão:"
docker-compose exec smtp ps aux | grep smtpd | grep -v grep || echo "   Nenhum smtpd rodando"
echo ""

# 2. Fazer uma conexão na porta 25
echo "2. Fazendo conexão na porta 25 para forçar smtpd a iniciar..."
(echo "EHLO test.local"; sleep 1; echo "QUIT") | timeout 5 docker-compose exec -T smtp nc localhost 25 2>&1 &
CONNECTION_PID=$!
sleep 2

# 3. Ver processos durante/logo após a conexão
echo "3. Processos smtpd DURANTE/APÓS a conexão:"
docker-compose exec smtp ps aux | grep smtpd | grep -v grep || echo "   Nenhum smtpd rodando"
echo ""

# 4. Aguardar conexão terminar
wait $CONNECTION_PID 2>/dev/null

# 5. Ver processos após conexão terminar
echo "5. Processos smtpd APÓS conexão terminar:"
sleep 2
docker-compose exec smtp ps aux | grep smtpd | grep -v grep || echo "   Nenhum smtpd rodando (normal - pode iniciar sob demanda)"
echo ""

# 6. Verificar se a porta 25 está realmente escutando
echo "6. Verificando se porta 25 está escutando:"
docker-compose exec smtp bash -c "ss -tlnp 2>/dev/null | grep ':25 ' || netstat -tlnp 2>/dev/null | grep ':25 ' || echo '   ss/netstat não disponível'"
echo ""

# 7. Testar resposta SMTP
echo "7. Testando resposta SMTP:"
SMTP_RESPONSE=$(echo "QUIT" | timeout 3 docker-compose exec -T smtp nc localhost 25 2>&1)
if echo "$SMTP_RESPONSE" | grep -q "220"; then
    echo -e "\033[0;32m✓ Postfix está respondendo!\033[0m"
    echo "$SMTP_RESPONSE" | head -1
else
    echo -e "\033[1;31m✗ Postfix NÃO está respondendo\033[0m"
    echo "   Resposta: $SMTP_RESPONSE"
fi
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
echo ""
echo "Nota: O smtpd pode iniciar sob demanda quando há conexão."
echo "Se o Postfix respondeu acima, está funcionando corretamente!"
