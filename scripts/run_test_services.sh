#!/bin/bash
# Executa test_services.sh dentro do container cliente (que está na rede aasr_net)
# Garante que a stack está no ar antes de correr os testes.
# Uso: a partir da raiz do projeto, ./scripts/run_test_services.sh

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "A subir serviços (docker-compose up -d)..."
docker-compose up -d

echo "A aguardar serviços iniciarem (60s)..."
sleep 60

echo "A executar testes dentro do container cliente..."
docker-compose exec -T cliente test_services.sh
