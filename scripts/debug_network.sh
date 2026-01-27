#!/bin/bash
# Debug de rede entre contentor cliente e SMTP

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=========================================="
echo "Debug de Rede - Cliente → SMTP"
echo "=========================================="
echo ""

echo "=== Teste 1: Resolução DNS do nome 'smtp' ==="
docker-compose run --rm cliente nslookup smtp
echo ""

echo "=== Teste 2: Ping ao SMTP (10.0.1.30) ==="
docker-compose run --rm cliente ping -c 2 10.0.1.30
echo ""

echo "=== Teste 3: Conexão TCP porta 25 do SMTP ==="
docker-compose run --rm cliente timeout 5 bash -c "echo QUIT | nc smtp 25"
echo ""

echo "=== Teste 4: Porta 25 dentro do container SMTP ==="
docker-compose exec -T smtp ss -tlnp | grep :25 || echo "ss falhou, tentando netstat..."
docker-compose exec -T smtp netstat -tlnp | grep :25 || echo "netstat também falhou"
echo ""

echo "=== Teste 5: Containers na rede aasr_net ==="
docker network inspect git_aasr_net | grep -A 30 '"Containers"'
echo ""

echo "=========================================="
echo "Debug concluído"
echo "=========================================="
