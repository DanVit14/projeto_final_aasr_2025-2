# Database (PostgreSQL)

## 📋 Visão Geral

**Função:** Banco de dados corporativo e auditoria  
**IP:** 10.0.1.40  
**Container:** database  
**Software:** PostgreSQL 15

---

## 🔧 Configuração

### Credenciais

- **Database:** `empresa_db`
- **Usuário:** `app_user`
- **Senha:** `app_password`
- **Admin:** `postgres` / `postgres`

### Portas

| Porta Host | Porta Container |
|------------|-----------------|
| 5432 | 5432 |

### Volumes

- **Dados:** `postgres_data` (persistente)
- **Backups:** `./backups/` (host)
- **Init SQL:** `./docker/database/init.sql`

---

## 📊 Tabelas

### audit_log

Tabela de auditoria para teste E2E:

```sql
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT NOW(),
    test_id VARCHAR(100),
    usuario VARCHAR(50),
    acao TEXT,
    status VARCHAR(20)
);
```

---

## ✅ Validação

### Conectar ao Banco

```bash
# Do container database
docker-compose exec database psql -U app_user -d empresa_db

# Do cliente (direto)
docker-compose exec cliente psql -h 10.0.1.40 -U app_user -d empresa_db

# Do cliente (via firewall)
docker-compose exec cliente psql -h 10.0.1.20 -U app_user -d empresa_db
```

### Listar Tabelas

```sql
\dt
```

### Consultar Auditoria

```sql
SELECT * FROM audit_log ORDER BY timestamp DESC LIMIT 10;
```

---

## 💾 Backup e Restore

### Backup Manual

```bash
# Backup completo
docker-compose exec database pg_dump -U app_user empresa_db \
  > backups/backup_$(date +%Y%m%d_%H%M%S).sql

# Backup compactado
docker-compose exec database pg_dump -U app_user empresa_db \
  | gzip > backups/backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

### Restore

```bash
# Restaurar backup
docker-compose exec -T database psql -U app_user -d empresa_db \
  < backups/backup_YYYYMMDD_HHMMSS.sql

# Restaurar backup compactado
gunzip < backups/backup_YYYYMMDD_HHMMSS.sql.gz \
  | docker-compose exec -T database psql -U app_user -d empresa_db
```

### Backup Automatizado

```bash
# Criar script de backup (exemplo)
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker-compose exec database pg_dump -U app_user empresa_db \
  | gzip > backups/backup_$DATE.sql.gz
  
# Manter apenas últimos 7 dias
find backups/ -name "backup_*.sql.gz" -mtime +7 -delete
```

---

## 🔗 Integração com Firewall

O cliente acessa o database **através do firewall** usando port forwarding:

```
Cliente → Firewall:5432 (DNAT) → Database:5432
```

Isso demonstra integração real do firewall no fluxo de dados.

---

## 🛠️ Troubleshooting

### Banco Não Aceita Conexões

**Verificar:**
```bash
# PostgreSQL rodando?
docker-compose exec database pg_isready -U postgres

# Logs
docker-compose logs database | tail -50
```

**Reiniciar:**
```bash
docker-compose restart database
```

### Tabela Não Existe

**Criar manualmente:**
```bash
docker-compose exec database psql -U app_user -d empresa_db <<EOF
CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT NOW(),
    test_id VARCHAR(100),
    usuario VARCHAR(50),
    acao TEXT,
    status VARCHAR(20)
);
EOF
```

### Permissões Negadas

**Verificar role:**
```sql
\du app_user
```

**Dar permissões:**
```sql
GRANT ALL PRIVILEGES ON DATABASE empresa_db TO app_user;
GRANT ALL ON audit_log TO app_user;
```

### Disco Cheio

**Ver tamanho do banco:**
```sql
SELECT pg_size_pretty(pg_database_size('empresa_db'));
```

**Limpar dados de teste:**
```sql
DELETE FROM audit_log WHERE test_id LIKE 'TEST_E2E_%';
VACUUM FULL;
```

---

## 📁 Arquivos Relacionados

- `docker/database/Dockerfile`
- `docker/database/init.sql` (estrutura inicial)
- `backups/` (diretório de backups)
- `scripts/test_acls.sh` (ACLs demonstradas no database)

---

**Database: Armazenamento persistente e auditoria de transações.** ✅
