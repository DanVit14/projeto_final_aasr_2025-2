FROM postgres:15

# Instalar ferramentas adicionais
RUN apt-get update && apt-get install -y \
    postgresql-contrib \
    && rm -rf /var/lib/apt/lists/*

COPY init.sql /docker-entrypoint-initdb.d/
COPY backup_db.sh /usr/local/bin/
COPY restore_db.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/backup_db.sh /usr/local/bin/restore_db.sh

EXPOSE 5432
