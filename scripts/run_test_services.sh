#!/bin/bash
# Executa test_services.sh dentro do container cliente (que está na rede aasr_net)
# Garante que a stack está no ar antes de correr os testes.
# Uso: a partir da raiz do projeto, ./scripts/run_test_services.sh

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "A subir serviços (docker-compose up -d)..."
docker-compose up -d

echo "A aguardar Postfix ficar pronto (até 180s)..."
max=60
n=0
while [ $n -lt $max ]; do
  # Verificar se o Postfix está a responder dentro do próprio container SMTP
  if docker-compose exec -T smtp bash -c "echo 'QUIT' | timeout 3 nc 127.0.0.1 25 2>/dev/null | head -1 | grep -q 220"; then
    echo "Postfix pronto após $((n * 3)) segundos."
    break
  fi
  n=$((n+1))
  [ $n -lt $max ] && sleep 3
done

if [ $n -eq $max ]; then
  echo "AVISO: Postfix não respondeu após 180s. Testes podem falhar."
  echo "Verificando status do Postfix:"
  docker-compose exec -T smtp postfix status || true
else
  echo "A aguardar mais 5s para estabilizar..."
  sleep 5
fi

echo ""
echo "A executar testes dentro do container cliente..."
docker-compose exec -T cliente test_services.sh
