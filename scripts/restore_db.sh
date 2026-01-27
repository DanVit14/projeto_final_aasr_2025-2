#!/bin/bash
# Restauração do PostgreSQL — roda no container database

set -e

if [ -z "$1" ]; then
    echo "Uso: $0 <arquivo_backup.sql.gz>"
    echo "Ex.: $0 backups/backup_20250126_120000.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

# Caminho absoluto e basename para o container
if [ ! -f "${BACKUP_FILE}" ]; then
    BACKUP_FILE="${PROJECT_DIR}/${BACKUP_FILE}"
fi
if [ ! -f "${BACKUP_FILE}" ]; then
    echo "Erro: ficheiro não encontrado: $1"
    exit 1
fi

BN=$(basename "${BACKUP_FILE}")
echo "A restaurar: ${BN} (no container: /backups/${BN})"

# Copiar para o volume do container se ainda não estiver em ./backups
if [[ "$(dirname "$(realpath "${BACKUP_FILE}")")" != "$(realpath "${PROJECT_DIR}/backups")" ]]; then
    mkdir -p "${PROJECT_DIR}/backups"
    cp "${BACKUP_FILE}" "${PROJECT_DIR}/backups/${BN}"
    BACKUP_FILE="${PROJECT_DIR}/backups/${BN}"
fi

# Executar restore dentro do container
docker-compose exec -T database /usr/local/bin/restore_db.sh "/backups/${BN}" 2>/dev/null || {
    echo "Fallback: psql direto (host)..."
    read -p "Sobrescrever banco? (s/N): " ok
    [ "$ok" = "s" ] || [ "$ok" = "S" ] || exit 0
    gunzip -c "${BACKUP_FILE}" | PGPASSWORD=db_pass_123 psql -h 127.0.0.1 -p 5432 -U app_user -d empresa_db
}
echo "Restauração concluída."
echo ""
