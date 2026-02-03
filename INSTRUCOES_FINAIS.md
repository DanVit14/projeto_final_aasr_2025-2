# Instruções Finais - Preparação para Apresentação

## ✅ O que foi feito

### 1. Implementações Completas
- ✅ **ACLs**: Script `test_acls.sh` demonstra permissões granulares por departamento
- ✅ **Firewall**: Script `test_firewall.sh` valida regras iptables
- ✅ **NTP**: Script `test_ntp.sh` verifica sincronização chrony
- ✅ **Testes Master**: Script `run_all_tests.sh` executa tudo sequencialmente

### 2. Documentação Completa
- ✅ **TOPOLOGIA.md**: Diagrama de rede + endereçamento detalhado
- ✅ **DECISOES_TECNICAS.md**: Decisões de arquitetura e problemas resolvidos
- ✅ **OPCAO_SEM_ANTIVIRUS.md**: Justificativa técnica fundamentada
- ✅ **EVIDENCIAS/README.md**: Guia para coleta de evidências

### 3. Commits Realizados
Todos os arquivos foram comitados no Git:
```
commit d28348e - Implementar ACLs e documentação completa do projeto
commit b88a402 - Fix: adicionar smtpd_relay_restrictions obrigatório
```

---

## 🚀 Próximos Passos na VM

### Passo 1: Sincronizar com Git

Na **tua máquina** (host):
```bash
cd /home/daniel/aasr/git
git push origin main
```

Na **VM**:
```bash
cd ~/aasr/projeto_final_aasr_2025-2
git pull origin main
```

### Passo 2: Rebuild do Container Database (IMPORTANTE!)

O container `database` precisa ser rebuilded porque adicionamos o pacote `acl`:

```bash
docker-compose down
docker-compose build database --no-cache
docker-compose up -d
```

**Tempo estimado**: 2-3 minutos

### Passo 3: Executar TODOS os Testes

```bash
./scripts/run_all_tests.sh | tee docs/EVIDENCIAS/output_completo.txt
```

Este script executa **sequencialmente**:
1. Conectividade de serviços (LDAP, DB, SMTP, rsyslog, SMB)
2. CRUD do PostgreSQL
3. Backup do banco de dados
4. ACLs (permissões avançadas)
5. Firewall (iptables/Netfilter)
6. NTP (sincronização de tempo)
7. SMTP (envio e entrega completa)

**Tempo estimado**: 3-5 minutos

### Passo 4: Testar Restore do Backup

Depois de executar `run_all_tests.sh`, terás um backup em `backups/`:

```bash
ls -lh backups/

# Testar restore (vai pedir confirmação)
./scripts/restore_db.sh backups/backup_YYYYMMDD_HHMMSS.sql.gz

# Verificar que dados foram restaurados
./scripts/test_crud_db.sh
```

### Passo 5: Coletar Evidências Adicionais

```bash
# Informações de rede
docker network inspect aasr_net > docs/EVIDENCIAS/network_inspect.txt

# Status dos containers
docker-compose ps > docs/EVIDENCIAS/containers_status.txt

# Consumo de recursos
docker stats --no-stream > docs/EVIDENCIAS/resource_usage.txt

# Ver backups criados
ls -lh backups/ > docs/EVIDENCIAS/backups_list.txt
```

### Passo 6: Screenshots

Capturar prints de:
1. **Saída de `run_all_tests.sh`** (especialmente o resumo final)
2. **ACLs configuradas** (`test_acls.sh` mostrando `getfacl`)
3. **Firewall rules** (`test_firewall.sh` mostrando iptables)
4. **NTP tracking** (`test_ntp.sh` mostrando chronyc)
5. **Backup criado** (`ls -lh backups/`)
6. **Restore bem-sucedido**

---

## 📋 Checklist Pré-Apresentação

### Funcionamento
- [ ] `git pull` executado na VM
- [ ] Container `database` rebuilded
- [ ] `run_all_tests.sh` executado com sucesso
- [ ] Backup criado em `backups/`
- [ ] Restore testado e funcional
- [ ] Todos os 6 serviços respondendo OK

### Documentação
- [ ] `docs/TOPOLOGIA.md` lido e compreendido
- [ ] `docs/DECISOES_TECNICAS.md` lido (especialmente Problema #4: smtpd_relay_restrictions)
- [ ] `docs/OPCAO_SEM_ANTIVIRUS.md` lido (para justificar se perguntado)
- [ ] `docs/EVIDENCIAS/output_completo.txt` gerado

### Preparação
- [ ] Screenshots salvos
- [ ] Comandos de demonstração ensaiados (ver `docs/EVIDENCIAS/README.md`)
- [ ] Saber entrar em qualquer container: `docker-compose exec <serviço> bash`
- [ ] Saber executar modificações ao vivo (adicionar user LDAP, criar tabela DB, etc.)

---

## 🎯 Comandos Rápidos para Demonstração

### Ver todos os serviços
```bash
docker-compose ps
```

### Testar conectividade
```bash
./scripts/run_test_services.sh
```

### Ver logs de um serviço
```bash
docker-compose logs -f smtp
docker-compose logs -f database
```

### Entrar em container
```bash
docker-compose exec ldap bash
docker-compose exec smtp bash
docker-compose exec database bash
```

### Reiniciar um serviço
```bash
docker-compose restart smtp
```

### Ver emails entregues
```bash
docker-compose exec smtp find /var/mail/vhosts/empresa.local/user1/Maildir/new -type f | wc -l
```

### Ver usuários LDAP
```bash
docker-compose exec ldap samba-tool user list
```

### Consultar banco de dados
```bash
docker-compose exec database psql -U app_user -d empresa_db -c "SELECT * FROM usuarios;"
```

---

## 🔧 Troubleshooting

### Se algum container não iniciar
```bash
docker-compose logs <serviço>
docker-compose down
docker-compose up -d
```

### Se SMTP falhar
```bash
docker-compose exec smtp postfix status
docker-compose exec smtp tail -20 /var/log/mail.log
```

### Se Database falhar
```bash
docker-compose exec database pg_isready -U app_user
docker-compose exec database psql -U app_user -d empresa_db -c "SELECT version();"
```

### Rebuild completo (se necessário)
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

---

## 📊 O que Esperar

### Tempos de Execução
- Startup completo: ~30-45s
- `run_all_tests.sh`: ~3-5 min
- Rebuild de container: ~2-3 min

### Consumo de Recursos (6 containers)
- RAM total: ~1.5-2 GB
- CPU: <10% em idle
- Disco: ~3 GB (incluindo volumes)

### Serviços Funcionais
1. ✅ LDAP/Samba AD (porta 389, 445)
2. ✅ Firewall (iptables ativo)
3. ✅ SMTP (porta 25, envio/entrega OK)
4. ✅ PostgreSQL (porta 5432, CRUD + backup/restore)
5. ✅ rsyslog (porta 514, recebendo logs)
6. ✅ NTP/chrony (sincronização ativa)

---

## 💡 Dicas para a Apresentação

1. **Começa com `docker-compose ps`** - mostra todos os serviços UP
2. **Executa `run_all_tests.sh`** - demonstra tudo de uma vez
3. **Destaca ACLs** - é o único ponto que pode ser questionado como "novo"
4. **Justifica antivírus** - lê `OPCAO_SEM_ANTIVIRUS.md` antes
5. **Prepara modificações ao vivo** - adicionar user LDAP, criar tabela, etc.
6. **Conhece os logs** - se algo falhar, sabes onde procurar

---

## ✅ Pronto!

Quando completares todos os passos acima, o projeto está **100% completo** e pronto para apresentação!

**Boa sorte! 🚀**
