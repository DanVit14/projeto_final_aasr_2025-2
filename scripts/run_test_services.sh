#!/bin/bash
# Executa test_services.sh dentro do container cliente (rede aasr_net)
# Garante que a stack está no ar e que o SMTP responde na porta 25 antes de correr os testes.
# Uso: a partir da raiz do projeto, ./scripts/run_test_services.sh

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "A subir serviços (docker-compose up -d)..."
docker-compose up -d

echo "A aguardar SMTP em localhost:2525 (máx. 180 s)..."
max=60
n=0
while [ $n -lt $max ]; do
  if (echo "QUIT" | timeout 4 nc localhost 2525 2>/dev/null) | grep -q "220"; then
    echo "SMTP a responder."
    break
  fi
  n=$((n+1))
  [ $n -lt $max ] && sleep 3
done
if [ $n -eq $max ]; then
  echo "Aviso: SMTP não respondeu em 180 s; testes SMTP podem falhar."
fi

docker-compose run --rm cliente test_services.sh
