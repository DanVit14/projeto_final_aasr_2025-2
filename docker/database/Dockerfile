FROM postgres:15

# Instalar ferramentas adicionais
RUN apt-get update && apt-get install -y \
    postgresql-contrib \
    && rm -rf /var/lib/apt/lists/*

COPY init.sql /docker-entrypoint-initdb.d/

# Criar scripts de backup/restore inline (já que não podemos acessar ../scripts do build context)
RUN echo '#!/bin/bash\n\
set -e\n\
BACKUP_DIR="/backups"\n\
TIMESTAMP=$(date +%Y%m%d_%H%M%S)\n\
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.sql"\n\
DB_NAME="empresa_db"\n\
DB_USER="app_user"\n\
DB_PASSWORD="db_pass_123"\n\
DB_HOST="localhost"\n\
echo "Iniciando backup do banco de dados..."\n\
mkdir -p "${BACKUP_DIR}"\n\
PGPASSWORD="${DB_PASSWORD}" pg_dump -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" > "${BACKUP_FILE}"\n\
gzip "${BACKUP_FILE}"\n\
BACKUP_FILE="${BACKUP_FILE}.gz"\n\
echo "Backup concluído: ${BACKUP_FILE}"\n\
cd "${BACKUP_DIR}"\n\
ls -t backup_*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm -f\n\
echo "Backup finalizado com sucesso!"' > /usr/local/bin/backup_db.sh && \
    chmod +x /usr/local/bin/backup_db.sh

RUN echo '#!/bin/bash\n\
set -e\n\
if [ -z "$1" ]; then\n\
    echo "Uso: $0 <arquivo_backup.sql[.gz]>"\n\
    exit 1\n\
fi\n\
BACKUP_FILE="$1"\n\
if [ ! -f "${BACKUP_FILE}" ]; then\n\
    echo "Erro: Arquivo não encontrado: ${BACKUP_FILE}"\n\
    exit 1\n\
fi\n\
DB_NAME="empresa_db"\n\
DB_USER="app_user"\n\
DB_PASSWORD="db_pass_123"\n\
DB_HOST="localhost"\n\
echo "Iniciando restauração..."\n\
if [[ "${BACKUP_FILE}" == *.gz ]]; then\n\
    TEMP_FILE=$(mktemp)\n\
    gunzip -c "${BACKUP_FILE}" > "${TEMP_FILE}"\n\
    BACKUP_FILE="${TEMP_FILE}"\n\
fi\n\
PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" < "${BACKUP_FILE}"\n\
[ -n "${TEMP_FILE}" ] && [ -f "${TEMP_FILE}" ] && rm "${TEMP_FILE}"\n\
echo "Restauração concluída!"' > /usr/local/bin/restore_db.sh && \
    chmod +x /usr/local/bin/restore_db.sh

EXPOSE 5432
