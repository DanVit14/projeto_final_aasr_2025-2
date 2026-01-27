#!/bin/bash
# Script para verificar se o smtpd está escutando

set +e

echo "=========================================="
echo "Verificando smtpd"
echo "=========================================="
echo ""

# 1. Ver processos smtpd
echo "1. Processos smtpd:"
docker-compose exec smtp ps aux | grep smtpd | grep -v grep
echo ""

# 2. Ver argumentos do smtpd
echo "2. Argumentos do smtpd:"
docker-compose exec smtp ps aux | grep smtpd | grep -v grep | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}'
echo ""

# 3. Verificar se está escutando (usando /proc)
echo "3. Verificando conexões do processo smtpd:"
SMTPD_PID=$(docker-compose exec smtp ps aux | grep "smtpd" | grep -v grep | head -1 | awk '{print $2}')
if [ -n "$SMTPD_PID" ]; then
    echo "   PID do smtpd: $SMTPD_PID"
    echo "   Verificando conexões..."
    docker-compose exec smtp cat /proc/$SMTPD_PID/net/tcp 2>/dev/null | grep -E "0050|:19 " || echo "   Não encontrou conexão na porta 25 (0050 em hex = 25 em decimal)"
else
    echo "   Nenhum processo smtpd encontrado"
fi
echo ""

# 4. Verificar logs do Postfix para erros de bind
echo "4. Erros relacionados a porta 25 nos logs:"
docker-compose logs smtp 2>&1 | grep -iE "bind|25|smtp.*error|cannot.*listen" | tail -10
echo ""

# 5. Verificar master.cf
echo "5. Configuração do master.cf (linha smtp):"
docker-compose exec smtp grep "^smtp" /etc/postfix/master.cf
echo ""

# 6. Tentar verificar diretamente se a porta está aberta
echo "6. Testando conexão direta:"
docker-compose exec smtp bash -c 'timeout 2 bash -c "echo > /dev/tcp/localhost/25" 2>&1 && echo "   ✓ Porta 25 está acessível" || echo "   ✗ Porta 25 NÃO está acessível"'
echo ""

echo "=========================================="
echo "Verificação concluída!"
echo "=========================================="
