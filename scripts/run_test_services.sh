#!/bin/bash
# Executa test_services.sh dentro do container cliente (rede aasr_net)
# Uso: a partir da raiz do projeto, ./scripts/run_test_services.sh

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
docker-compose run --rm cliente test_services.sh
