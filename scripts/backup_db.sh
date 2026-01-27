#!/bin/bash
# Backup do PostgreSQL — corre no container database (./backups = /backups no container)
# Uso: a partir da raiz do projeto, ./scripts/backup_db.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"
mkdir -p ./backups

if docker-compose exec -T database /usr/local/bin/backup_db.sh 2>/dev/null; then
    echo "Backup concluído. Ficheiros em ./backups/"
    ls -la ./backups/*.sql.gz 2>/dev/null | tail -3
else
    echo "A executar backup direto (host com porta 5432)..."
    PGPASSWORD=db_pass_123 pg_dump -h 127.0.0.1 -p 5432 -U app_user -d empresa_db | gzip > "./backups/backup_$(date +%Y%m%d_%H%M%S).sql.gz"
    echo "Backup salvo em ./backups/"
fi
