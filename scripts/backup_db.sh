#!/bin/bash
# Script de backup do banco de dados PostgreSQL

set -e

BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.sql"

# Variáveis do banco (ajustar conforme docker-compose.yml)
DB_NAME="empresa_db"
DB_USER="app_user"
DB_PASSWORD="db_pass_123"
# Dentro do container, usar localhost
DB_HOST="localhost"

echo "Iniciando backup do banco de dados..."
echo "Banco: ${DB_NAME}"
echo "Arquivo: ${BACKUP_FILE}"

# Criar diretório de backup se não existir
mkdir -p "${BACKUP_DIR}"

# Executar backup
PGPASSWORD="${DB_PASSWORD}" pg_dump -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" > "${BACKUP_FILE}"

# Compactar backup
gzip "${BACKUP_FILE}"
BACKUP_FILE="${BACKUP_FILE}.gz"

echo "Backup concluído: ${BACKUP_FILE}"
echo "Tamanho: $(du -h ${BACKUP_FILE} | cut -f1)"

# Manter apenas os últimos 7 backups
cd "${BACKUP_DIR}"
ls -t backup_*.sql.gz | tail -n +8 | xargs -r rm -f

echo "Backup finalizado com sucesso!"
