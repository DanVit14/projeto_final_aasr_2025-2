#!/bin/bash
# Teste manual detalhado do SMTP

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=========================================="
echo "Teste SMTP Manual - Detalhado"
echo "=========================================="
echo ""

echo "1. Verificar se porta 25 está acessível via TCP:"
docker-compose exec -T cliente timeout 5 bash -c "cat < /dev/null > /dev/tcp/smtp/25 && echo 'Porta 25 acessível'" || echo "Porta 25 não acessível"
echo ""

echo "2. Testar com netcat (3 tentativas):"
for i in 1 2 3; do
    echo "Tentativa $i:"
    docker-compose exec -T cliente bash -c "echo 'QUIT' | timeout 8 nc -w 5 smtp 25 2>&1" | head -5
    sleep 2
done
echo ""

echo "3. Verificar resolução DNS do nome 'smtp':"
docker-compose exec -T cliente getent hosts smtp
echo ""

echo "4. Verificar se SMTP está a escutar na porta 25:"
docker-compose exec -T smtp ss -tlnp | grep :25 || echo "ss não mostrou porta 25"
echo ""

echo "5. Testar conexão ao IP direto 10.0.1.30:"
docker-compose exec -T cliente bash -c "echo 'QUIT' | timeout 8 nc -w 5 10.0.1.30 25 2>&1" | head -5
echo ""

echo "=========================================="
