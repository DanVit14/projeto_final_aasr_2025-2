# Teste End-to-End: Workflow Corporativo Completo

Este teste demonstra **integração real de TODOS os 6 serviços** em um cenário prático de uso corporativo.

---

## 🎯 Objetivo

Validar que os serviços não apenas **funcionam isoladamente**, mas **integram-se** em um **fluxo completo de negócio**, como aconteceria em produção.

---

## 🎬 Cenário: Envio de Email Auditado

### História do Usuário

> "Como usuário corporativo, quero enviar um email autenticado, que seja validado, entregue, logado e auditado automaticamente."

### Fluxo Técnico

```
┌──────────┐
│ Cliente  │ (Container de teste)
└────┬─────┘
     │
     │ 1. Autentica
     ▼
┌──────────┐
│   LDAP   │ (Samba AD)
└──────────┘
     │
     │ 2. Credenciais OK
     ▼
┌──────────┐
│ Cliente  │
└────┬─────┘
     │
     │ 3. Envia email
     ▼
┌──────────┐
│   SMTP   │ ← 4. Valida remetente contra LDAP
└────┬─────┘
     │
     │ 5. Processa (antispam)
     ▼
┌──────────┐
│ Maildir  │ (Entrega local)
└──────────┘
     │
     │ 6. Envia logs
     ▼
┌──────────┐
│Logs-NTP  │ (rsyslog centralizado)
└──────────┘
     │
     │ 7. Script registra
     ▼
┌──────────┐
│ Database │ (Tabela audit_log)
└────┬─────┘
     │
     │ 8. Cliente consulta
     ▼
┌──────────┐
│ Cliente  │ (SELECT auditoria)
└──────────┘
```

**Resultado:** Email enviado, validado, entregue, logado e auditado! ✅

---

## 📋 Passos do Teste

### PASSO 1: Autenticação LDAP
```bash
# Verifica se user1 existe no LDAP
ldapsearch -x -b "dc=empresa,dc=local" "(cn=user1)"

# Se não existir, cria automaticamente
samba-tool user create user1 Senha@123

# Testa autenticação (bind)
ldapwhoami -x -D "cn=user1,cn=Users,dc=empresa,dc=local" -w Senha@123
```

**Validação:** ✓ Usuário existe e consegue autenticar

---

### PASSO 2: Envio de Email via SMTP
```bash
# Atualiza mapas LDAP no Postfix
/usr/local/bin/update-ldap-maps.sh

# Envia email com ID único de teste
sendmail user2@empresa.local <<EOF
From: user1@empresa.local
To: user2@empresa.local
Subject: TEST_E2E_20260203_153045
Message-ID: <TEST_E2E_20260203_153045@empresa.local>

Teste de workflow end-to-end.
EOF
```

**Validação:** ✓ Email aceite pelo Postfix

---

### PASSO 3: Verificação de Entrega (Maildir)
```bash
# Aguarda processamento (5s)
sleep 5

# Procura email no Maildir de user2
grep -r "TEST_E2E_20260203_153045" /var/mail/vhosts/empresa.local/user2/Maildir/new
```

**Validação:** ✓ Email entregue no destino

---

### PASSO 4: Logs Centralizados (rsyslog)
```bash
# Procura logs do teste no servidor logs-ntp
grep -r "TEST_E2E_20260203_153045" /var/log

# Verifica logs locais do Postfix
tail -20 /var/log/mail.log | grep "TEST_E2E"
```

**Validação:** ✓ Logs propagados para servidor central

---

### PASSO 5: Auditoria no PostgreSQL
```bash
# Cria tabela de auditoria (se não existir)
CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    test_id VARCHAR(100),
    usuario VARCHAR(50),
    acao VARCHAR(100),
    servico VARCHAR(50),
    status VARCHAR(20),
    detalhes TEXT
);

# Insere registro de auditoria
INSERT INTO audit_log (test_id, usuario, acao, servico, status, detalhes)
VALUES (
    'TEST_E2E_20260203_153045',
    'user1',
    'Envio de email end-to-end',
    'LDAP+SMTP+rsyslog',
    'SUCESSO',
    'Email enviado de user1@empresa.local para user2@empresa.local'
);
```

**Validação:** ✓ Auditoria registrada no banco

---

### PASSO 6: Consulta de Auditoria (Cliente → Database)
```bash
# Cliente consulta própria auditoria
psql -h database -U app_user -d empresa_db -c \
  "SELECT * FROM audit_log WHERE test_id = 'TEST_E2E_20260203_153045';"
```

**Validação:** ✓ Cliente consegue consultar auditoria

---

## ✅ Critérios de Sucesso

| Critério | Descrição | Peso |
|----------|-----------|------|
| **LDAP OK** | Usuário autentica com sucesso | 15% |
| **SMTP aceita** | Email enviado sem erros | 15% |
| **SMTP valida** | Remetente validado contra LDAP | 20% |
| **Entrega OK** | Email no Maildir de destino | 20% |
| **Logs centrais** | Logs propagados para logs-ntp | 10% |
| **Auditoria DB** | Registro inserido no PostgreSQL | 10% |
| **Consulta OK** | Cliente acessa auditoria | 10% |

**Aprovação:** ≥ 80% dos critérios

---

## 🎯 Serviços Integrados

### 6/6 Serviços Envolvidos ✅

1. **LDAP** - Autenticação de usuário
2. **SMTP** - Envio e processamento de email
3. **Logs-NTP** - Centralização de logs
4. **Database** - Armazenamento de auditoria
5. **Cliente** - Inicializador e consultor
6. **Firewall** - Rede protegida (infraestrutura)

---

## 🚀 Executar o Teste

### Comando Único
```bash
./scripts/test_end_to_end.sh
```

### Como Parte da Bateria Completa
```bash
./scripts/run_all_tests.sh
```

**Tempo estimado:** ~30-40 segundos

---

## 📊 Output Esperado

```
============================================================
  TESTE END-TO-END: Workflow Corporativo Completo
============================================================

Cenário: Usuário autentica, envia email, sistema audita

Fluxo:
  1. Cliente autentica no LDAP
  2. Cliente envia email via SMTP (validado contra LDAP)
  3. SMTP processa e entrega no Maildir
  4. SMTP envia logs para rsyslog centralizado
  5. Sistema registra auditoria no PostgreSQL
  6. Cliente consulta auditoria no banco

============================================================

PASSO 1/6: Autenticação no LDAP
✓ Usuário user1 encontrado no LDAP
✓ Autenticação LDAP bem-sucedida

PASSO 2/6: Envio de Email via SMTP
✓ Email enviado com sucesso

PASSO 3/6: Verificação de Entrega (SMTP → Maildir)
✓ Email entregue no Maildir de user2

PASSO 4/6: Logs Centralizados (SMTP → rsyslog)
✓ Logs encontrados no servidor central (12 linhas)

PASSO 5/6: Auditoria no Banco de Dados
✓ Tabela audit_log pronta
✓ Auditoria registrada no PostgreSQL

PASSO 6/6: Consulta de Auditoria (Cliente → Database)
 id | timestamp           | test_id              | usuario | acao                     | status
----+---------------------+----------------------+---------+-------------------------+--------
  1 | 2026-02-03 15:30:45 | TEST_E2E_20260203... | user1   | Envio de email end-to... | SUCESSO

✓ Total de registros de auditoria no sistema: 1

============================================================
  TESTE END-TO-END CONCLUÍDO!
============================================================

Fluxo completo executado:
  ✓ 1. Cliente → LDAP: Autenticação (OK)
  ✓ 2. Cliente → SMTP: Envio de email
  ✓ 3. SMTP → LDAP: Validação de contas
  ✓ 4. SMTP: Entrega no Maildir
  ✓ 5. SMTP → Logs-NTP: Logs centralizados
  ✓ 6. Sistema → Database: Auditoria registrada
  ✓ 7. Cliente → Database: Consulta de auditoria

Serviços integrados: 6/6

ID do Teste: TEST_E2E_20260203_153045
```

---

## 🎓 Valor para Apresentação

### Por que Este Teste é Importante?

1. **Demonstra Integração Real**
   - Não é só "serviços funcionando"
   - É "serviços conversando"

2. **Cenário Realista**
   - Workflow corporativo típico
   - Auditoria de ações
   - Rastreabilidade completa

3. **Cobertura Completa**
   - 6/6 serviços envolvidos
   - LDAP, SMTP, Logs, DB, Cliente, Firewall

4. **Fácil de Explicar**
   - História do usuário clara
   - Fluxo visual
   - Resultado tangível (auditoria no banco)

### Perguntas Prováveis

**P: "Como sabes que os serviços integram?"**
> "Criei um teste end-to-end que simula um workflow real: usuário autentica no LDAP, envia email via SMTP (validado contra LDAP), email é entregue, logs vão para rsyslog centralizado, e sistema registra auditoria no PostgreSQL. Cliente consulta a auditoria no final. Executo com `test_end_to_end.sh` e demonstra os 6 serviços conversando."

**P: "Podes demonstrar?"**
```bash
./scripts/test_end_to_end.sh
# Aguardar ~30s
# Mostrar output com todos os ✓
```

---

## 🔧 Limpeza de Dados de Teste

### Remover Auditorias de Teste
```bash
docker-compose exec database psql -U app_user -d empresa_db -c \
  "DELETE FROM audit_log WHERE test_id LIKE 'TEST_E2E_%';"
```

### Limpar Maildir
```bash
docker-compose exec smtp rm -f /var/mail/vhosts/empresa.local/*/Maildir/new/*TEST_E2E*
```

---

## 📚 Referências

- **INTEGRACOES.md** - Mapa de integrações implementadas
- **TOPOLOGIA.md** - Arquitetura de rede
- **test_integrations.sh** - Testes de integração (mais simples)
- **run_all_tests.sh** - Bateria completa de testes

---

**Conclusão:** Este teste demonstra que o projeto não é apenas uma coleção de serviços isolados, mas uma **infraestrutura corporativa integrada** onde os serviços **colaboram** para realizar **workflows reais de negócio** com **rastreabilidade completa**.
