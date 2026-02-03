# Scripts de Teste

## 📋 Scripts Disponíveis

### Teste Completo (Recomendado)

```bash
# Executar todos os testes (individuais + E2E)
./scripts/test_all.sh
```

---

### Testes Individuais por Serviço

| Script | Serviço | O que testa |
|--------|---------|-------------|
| `test_firewall.sh` | Firewall | Regras iptables, port forwarding, contadores |
| `test_ldap.sh` | LDAP | Samba AD DC, usuários, conectividade |
| `test_smtp.sh` | SMTP | Postfix, porta 25, fila de emails |
| `test_database.sh` | Database | PostgreSQL, conexão, tabelas |
| `test_logs_ntp.sh` | Logs-NTP | Rsyslog UDP:514, logs remotos, Chrony |

**Executar:**
```bash
./scripts/test_firewall.sh
./scripts/test_ldap.sh
./scripts/test_smtp.sh
./scripts/test_database.sh
./scripts/test_logs_ntp.sh
```

---

### Teste de Integração End-to-End

```bash
# Teste completo de workflow corporativo (6 serviços integrados)
./scripts/test_end_to_end.sh
```

**O que faz:**
1. Autentica usuário no LDAP
2. Envia email via SMTP (validado contra LDAP)
3. Verifica entrega no Maildir
4. Confirma logs centralizados
5. Registra auditoria no Database
6. Consulta auditoria (via Firewall)

**Resultado:** Score 6/6 serviços ✓

---

### Teste Básico de Conectividade

```bash
# Teste rápido de disponibilidade (montado no container cliente)
docker-compose exec cliente /usr/local/bin/test_services.sh
```

---

### Backup e Restore (Database)

```bash
# Criar backup
./scripts/backup_db.sh

# Restaurar backup
./scripts/restore_db.sh [arquivo]
```

---

## 🚀 Uso Típico

### Para Validação Rápida

```bash
# Todos os testes de uma vez
./scripts/test_all.sh
```

### Para Teste Específico

```bash
# Apenas firewall
./scripts/test_firewall.sh

# Apenas SMTP
./scripts/test_smtp.sh
```

### Para Apresentação

```bash
# Demonstrar integração completa
./scripts/test_end_to_end.sh

# Salvar resultado
./scripts/test_end_to_end.sh > docs/EVIDENCIAS/teste_final.txt
```

---

## 📊 Tempo de Execução

| Script | Tempo Estimado |
|--------|---------------|
| `test_all.sh` | ~2 minutos |
| `test_end_to_end.sh` | ~60 segundos |
| Testes individuais | ~5-10 segundos cada |
| `test_services.sh` | ~30 segundos |

---

## ✅ Saída Esperada

Todos os scripts mostram:
- ✅ `✓` (verde) = Passou
- ❌ `✗` (vermelho) = Falhou
- ⚠️ `⚠` (amarelo) = Warning (não crítico)

---

## 📁 Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `test_all.sh` | Executa todos os testes |
| `test_end_to_end.sh` | Teste de integração completo |
| `test_firewall.sh` | Teste do firewall |
| `test_ldap.sh` | Teste do LDAP |
| `test_smtp.sh` | Teste do SMTP |
| `test_database.sh` | Teste do database |
| `test_logs_ntp.sh` | Teste de logs e NTP |
| `test_services.sh` | Teste básico (no container) |
| `backup_db.sh` | Backup do PostgreSQL |
| `restore_db.sh` | Restore do PostgreSQL |

**Total: 10 scripts essenciais** ✅

---

## 📚 Documentação

Ver documentação completa em:
- **Instalação:** `docs/01_INSTALACAO.md`
- **Topologia:** `docs/02_TOPOLOGIA.md`
- **Teste E2E:** `docs/03_TESTE_E2E.md`
- **Serviços:** `docs/servicos/*.md`

---

**Scripts organizados e focados no essencial!** ✅
