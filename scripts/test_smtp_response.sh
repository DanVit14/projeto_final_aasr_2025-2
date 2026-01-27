#!/bin/bash
# Script para testar resposta SMTP do Postfix

set +e

echo "=========================================="
echo "Testando Resposta SMTP do Postfix"
echo "=========================================="
echo ""

# 1. Teste básico com nc
echo "1. Teste com nc (netcat):"
echo "QUIT" | timeout 3 docker-compose exec -T smtp nc localhost 25 2>&1
echo ""

# 2. Teste com telnet (se disponível)
echo "2. Teste com telnet:"
if docker-compose exec -T smtp which telnet >/dev/null 2>&1; then
    (echo "QUIT"; sleep 1) | timeout 3 docker-compose exec -T smtp telnet localhost 25 2>&1 | head -5
else
    echo "   telnet não está disponível"
fi
echo ""

# 3. Teste usando bash TCP
echo "3. Teste usando bash TCP:"
docker-compose exec smtp bash -c 'exec 3<>/dev/tcp/localhost/25 && cat <&3 & echo "EHLO test" >&3 && sleep 1 && kill %1 2>/dev/null' 2>&1 | head -10
echo ""

# 4. Verificar se há algum filtro ou firewall bloqueando
echo "4. Verificando se há processos bloqueando:"
docker-compose exec smtp netstat -tlnp 2>/dev/null | grep ":25" || docker-compose exec smtp ss -tlnp 2>/dev/null | grep ":25" || echo "   netstat/ss não disponível"
echo ""

# 5. Verificar logs do Postfix em tempo real durante o teste
echo "5. Iniciando teste e verificando logs simultaneamente:"
echo "   (Enviando EHLO e verificando logs...)"
docker-compose exec smtp bash -c 'echo "EHLO test.local" | timeout 2 nc localhost 25' 2>&1 &
sleep 1
docker-compose logs --tail=5 smtp 2>&1 | grep -iE "smtp|connection|connect|ehlo" || echo "   Nenhum log relevante encontrado"
echo ""

# 6. Verificar se o Postfix está realmente escutando
echo "6. Verificando processos escutando na porta 25:"
docker-compose exec smtp lsof -i :25 2>/dev/null || docker-compose exec smtp fuser 25/tcp 2>/dev/null || echo "   lsof/fuser não disponível - tentando método alternativo"
# Método alternativo: verificar via /proc
for pid in $(docker-compose exec smtp pgrep -f smtpd); do
    echo "   Verificando PID $pid..."
    docker-compose exec smtp cat /proc/$pid/net/tcp 2>/dev/null | grep -q "0050" && echo "     ✓ PID $pid está escutando na porta 25" || echo "     ✗ PID $pid não está escutando na porta 25"
done
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
