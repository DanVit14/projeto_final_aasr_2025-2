#!/bin/bash
# Teste simples e direto do Postfix

set +e

echo "=========================================="
echo "Teste Simples do Postfix"
echo "=========================================="
echo ""

# Teste 1: Usar telnet se disponível
echo "1. Teste com telnet (se disponível):"
if docker-compose exec -T smtp which telnet >/dev/null 2>&1; then
    (echo "EHLO test"; sleep 1; echo "QUIT") | timeout 5 docker-compose exec -T smtp telnet localhost 25 2>&1 | head -10
else
    echo "   telnet não está disponível"
fi
echo ""

# Teste 2: Usar nc com timeout curto
echo "2. Teste com nc (timeout 2s):"
echo "QUIT" | timeout 2 docker-compose exec -T smtp nc -w 1 localhost 25 2>&1
echo ""

# Teste 3: Usar bash TCP redirection
echo "3. Teste com bash TCP:"
docker-compose exec smtp bash -c 'timeout 2 bash -c "exec 3<>/dev/tcp/127.0.0.1/25 && cat <&3" 2>&1' | head -3 || echo "   Falhou"
echo ""

# Teste 4: Verificar se há resposta mesmo que não apareça
echo "4. Teste capturando qualquer saída:"
RESPONSE=$(timeout 3 docker-compose exec -T smtp bash -c 'echo "QUIT" | nc localhost 25 2>&1' 2>&1)
echo "   Resposta capturada:"
echo "$RESPONSE" | head -5 | sed 's/^/   /'
if [ -z "$RESPONSE" ]; then
    echo "   (Nenhuma resposta - Postfix pode não estar respondendo)"
fi
echo ""

# Teste 5: Verificar processos
echo "5. Processos relacionados:"
docker-compose exec smtp ps aux 2>/dev/null | grep -E "master|smtpd" | grep -v grep
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
