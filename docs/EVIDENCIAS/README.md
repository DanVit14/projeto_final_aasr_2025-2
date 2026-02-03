# Guia de Coleta de Evidências

Este diretório contém as evidências de funcionamento da infraestrutura corporativa.

## 📸 Como Coletar Evidências

### 1. Executar Todos os Testes

Na **VM**, executar:

```bash
cd ~/aasr/projeto_final_aasr_2025-2
./scripts/run_all_tests.sh | tee docs/EVIDENCIAS/output_completo.txt
```

Isso gerará um arquivo `output_completo.txt` com a saída de todos os testes.

### 2. Capturar Screenshots

Durante a execução, capturar prints de:

#### A. Testes de Conectividade
- `run_test_services.sh` mostrando todos os serviços OK

#### B. CRUD do Banco de Dados
- `test_crud_db.sh` com SELECT, INSERT, UPDATE, DELETE

#### C. Backup e Restore
- `backup_db.sh` criando arquivo `.sql.gz`
- `ls -lh backups/` mostrando backups criados
- `restore_db.sh` restaurando um backup

#### D. ACLs (Permissões Avançadas)
- `test_acls.sh` mostrando:
  - Criação de estrutura de diretórios
  - Configuração de ACLs por departamento
  - Output de `getfacl` com permissões granulares
  - Testes de acesso efetivo

#### E. Firewall
- `test_firewall.sh` mostrando:
  - Regras iptables ativas
  - Conectividade da rede 10.0.1.0/24
  - Portas permitidas/bloqueadas

#### F. NTP
- `test_ntp.sh` mostrando:
  - `chronyc tracking` com offset e status
  - `chronyc sources` com servidores NTP

#### G. SMTP
- `test_smtp_completo.sh` mostrando:
  - Conexão SMTP bem-sucedida
  - Email enviado e entregue no Maildir
  - Logs do Postfix

### 3. Evidências de Configuração

Capturar também:

```bash
# Topologia de rede
docker network inspect aasr_net > docs/EVIDENCIAS/network_inspect.txt

# Status dos containers
docker-compose ps > docs/EVIDENCIAS/containers_status.txt

# Consumo de recursos
docker stats --no-stream > docs/EVIDENCIAS/resource_usage.txt

# Estrutura de diretórios
tree -L 3 . > docs/EVIDENCIAS/project_structure.txt
```

### 4. Configurações Críticas

Incluir trechos de:

- `docker-compose.yml` (topologia)
- `docker/smtp/main.cf` (Postfix)
- `docker/smtp/master.cf` (serviços Postfix)
- `docker/firewall/iptables.rules` (firewall)
- `docker/database/init.sql` (estrutura DB)

## 📋 Checklist de Evidências

- [ ] `output_completo.txt` - Saída de todos os testes
- [ ] Screenshot: Teste de conectividade (6 serviços OK)
- [ ] Screenshot: CRUD do PostgreSQL
- [ ] Screenshot: Backup do banco criado
- [ ] Screenshot: ACLs configuradas (getfacl)
- [ ] Screenshot: Regras iptables ativas
- [ ] Screenshot: NTP sincronizado (chronyc tracking)
- [ ] Screenshot: Email entregue no Maildir
- [ ] `network_inspect.txt` - Configuração de rede
- [ ] `containers_status.txt` - Status dos containers
- [ ] `resource_usage.txt` - Consumo de RAM/CPU
- [ ] Trechos de configurações críticas

## 🎯 Para a Apresentação

### Demonstração Ao Vivo

Preparar os seguintes comandos para executar durante a apresentação:

#### 1. Iniciar a Infraestrutura
```bash
docker-compose up -d
docker-compose ps
```

#### 2. Testar Conectividade
```bash
./scripts/run_test_services.sh
```

#### 3. Demonstrar CRUD
```bash
./scripts/test_crud_db.sh
```

#### 4. Demonstrar ACLs
```bash
./scripts/test_acls.sh
```

#### 5. Demonstrar Firewall
```bash
./scripts/test_firewall.sh
```

#### 6. Demonstrar Backup/Restore
```bash
./scripts/backup_db.sh
ls -lh backups/
# Mostrar último backup criado
```

#### 7. Entrar em Containers (Se solicitado)
```bash
# LDAP
docker-compose exec ldap bash
samba-tool user list

# SMTP
docker-compose exec smtp bash
postqueue -p

# Database
docker-compose exec database bash
psql -U app_user -d empresa_db -c "SELECT * FROM usuarios;"
```

### Modificações Rápidas (Se Solicitado)

#### Adicionar Usuário LDAP
```bash
docker-compose exec ldap samba-tool user create teste123 Senha@123
docker-compose exec ldap samba-tool user list | grep teste123
```

#### Enviar Email de Teste
```bash
docker-compose exec smtp sendmail user1@empresa.local <<EOF
Subject: Teste durante apresentacao

Corpo do email de teste.
EOF

# Verificar entrega
docker-compose exec smtp find /var/mail/vhosts/empresa.local/user1/Maildir/new -type f
```

#### Adicionar Regra de Firewall
```bash
docker-compose exec firewall iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
docker-compose exec firewall iptables -L -n | grep 8080
```

#### Criar Tabela no PostgreSQL
```bash
docker-compose exec database psql -U app_user -d empresa_db -c "
CREATE TABLE IF NOT EXISTS teste (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100)
);
INSERT INTO teste (nome) VALUES ('Teste Apresentacao');
SELECT * FROM teste;
"
```

## 📁 Organização de Arquivos

```
docs/EVIDENCIAS/
├── README.md (este arquivo)
├── output_completo.txt
├── screenshots/
│   ├── 01_conectividade.png
│   ├── 02_crud_database.png
│   ├── 03_backup.png
│   ├── 04_acls.png
│   ├── 05_firewall.png
│   ├── 06_ntp.png
│   └── 07_smtp.png
├── configs/
│   ├── docker-compose.yml
│   ├── postfix_main.cf
│   ├── postfix_master.cf
│   ├── iptables.rules
│   └── init.sql
└── outputs/
    ├── network_inspect.txt
    ├── containers_status.txt
    ├── resource_usage.txt
    └── project_structure.txt
```

## 🎬 Vídeo (Opcional)

Se permitido, gravar um vídeo curto (3-5 min) demonstrando:
1. Startup da infraestrutura
2. Execução de `run_all_tests.sh`
3. Navegação pelos containers
4. Verificação de logs

Ferramentas: `asciinema`, `screen`, ou simplesmente gravar a tela.

---

**Próximo passo**: Executar `run_all_tests.sh` e coletar os outputs!
