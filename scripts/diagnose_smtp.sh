#!/bin/bash
# Script de diagnóstico do contentor SMTP
# Executa dentro da VM para verificar o estado do Postfix

echo "=========================================="
echo "Diagnóstico do SMTP"
echo "=========================================="
echo ""

echo "1. Estado do contentor SMTP:"
docker-compose ps smtp
echo ""

echo "2. Últimas 50 linhas dos logs do SMTP:"
docker-compose logs smtp | tail -50
echo ""

echo "3. Status do Postfix dentro do contentor:"
docker-compose exec -T smtp postfix status 2>&1 || echo "ERRO: postfix status falhou"
echo ""

echo "4. Processos em execução no contentor:"
docker-compose exec -T smtp ps aux | grep -E "(postfix|smtp|master)" | grep -v grep
echo ""

echo "5. Portas abertas no contentor:"
docker-compose exec -T smtp netstat -tlnp 2>/dev/null | grep -E "(25|587)" || echo "netstat não disponível"
echo ""

echo "6. Teste de conexão ao SMTP no host (localhost:25):"
timeout 3 bash -c "echo 'QUIT' | nc localhost 25" 2>&1 | head -5 || echo "ERRO: sem resposta"
echo ""

echo "7. Teste de conexão ao SMTP dentro do contentor (127.0.0.1:25):"
docker-compose exec -T smtp bash -c "timeout 3 bash -c \"echo 'QUIT' | nc 127.0.0.1 25\" 2>&1 | head -5" || echo "ERRO: sem resposta"
echo ""

echo "8. Verificar se init.sh terminou ou está em loop:"
docker-compose exec -T smtp ps aux | grep init.sh | grep -v grep || echo "init.sh já terminou ou não está em execução"
echo ""

echo "9. Conteúdo de /var/log/mail.log (últimas 30 linhas):"
docker-compose exec -T smtp tail -30 /var/log/mail.log 2>/dev/null || echo "mail.log não existe ou vazio"
echo ""

echo "=========================================="
echo "Diagnóstico concluído"
echo "=========================================="
