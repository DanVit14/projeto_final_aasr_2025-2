#!/bin/bash
# Debug de rede entre contentor cliente e SMTP

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=========================================="
echo "Debug de Rede - Cliente → SMTP"
echo "=========================================="
echo ""

echo "=== Teste 1: Descobrir nome da rede Docker ==="
NETWORK_NAME=$(docker network ls --format '{{.Name}}' | grep aasr_net | head -1)
echo "Rede encontrada: $NETWORK_NAME"
echo ""

echo "=== Teste 2: Listar containers na rede $NETWORK_NAME ==="
if [ -n "$NETWORK_NAME" ]; then
    docker network inspect "$NETWORK_NAME" | grep -A 30 '"Containers"'
else
    echo "ERRO: Rede aasr_net não encontrada!"
    docker network ls
fi
echo ""

echo "=== Teste 3: Verificar se SMTP está a escutar na porta 25 ==="
docker-compose exec -T smtp bash -c "timeout 2 cat < /dev/null > /dev/tcp/127.0.0.1/25 && echo 'Porta 25 OK'" || echo "Porta 25 não responde"
echo ""

echo "=== Teste 4: Conexão do cliente ao SMTP via netcat ==="
docker-compose run --rm cliente bash -c "timeout 5 bash -c \"echo QUIT | nc smtp 25\" || echo 'Falhou a conectar'"
echo ""

echo "=== Teste 5: IP do container SMTP ==="
docker inspect smtp_antivirus | grep -A 5 '"Networks"' | grep IPAddress
echo ""

echo "=== Teste 6: Testar conexão ao IP direto 10.0.1.30 ==="
docker-compose run --rm cliente bash -c "timeout 5 bash -c \"echo QUIT | nc 10.0.1.30 25\" || echo 'Falhou a conectar ao IP'"
echo ""

echo "=========================================="
echo "Debug concluído"
echo "=========================================="
