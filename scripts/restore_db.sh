#!/bin/bash
# Script de restauração do banco de dados PostgreSQL

set -e

if [ -z "$1" ]; then
    echo "Uso: $0 <arquivo_backup.sql[.gz]>"
    echo "Exemplo: $0 /backups/backup_20250126_120000.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"

# Verificar se o arquivo existe
if [ ! -f "${BACKUP_FILE}" ]; then
    echo "Erro: Arquivo não encontrado: ${BACKUP_FILE}"
    exit 1
fi

# Variáveis do banco
DB_NAME="empresa_db"
DB_USER="app_user"
DB_PASSWORD="db_pass_123"
# Dentro do container, usar localhost
DB_HOST="localhost"

echo "Iniciando restauração do banco de dados..."
echo "Banco: ${DB_NAME}"
echo "Arquivo: ${BACKUP_FILE}"

# Confirmar restauração
read -p "ATENÇÃO: Isso irá sobrescrever o banco atual. Continuar? (s/N): " confirm
if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
    echo "Restauração cancelada."
    exit 0
fi

# Descompactar se necessário
if [[ "${BACKUP_FILE}" == *.gz ]]; then
    echo "Descompactando backup..."
    TEMP_FILE=$(mktemp)
    gunzip -c "${BACKUP_FILE}" > "${TEMP_FILE}"
    BACKUP_FILE="${TEMP_FILE}"
fi

# Restaurar banco
echo "Restaurando banco de dados..."
PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" < "${BACKUP_FILE}"

# Limpar arquivo temporário se foi criado
if [ -n "${TEMP_FILE}" ] && [ -f "${TEMP_FILE}" ]; then
    rm "${TEMP_FILE}"
fi

echo "Restauração concluída com sucesso!"
