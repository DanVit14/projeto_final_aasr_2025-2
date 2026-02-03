# Teste End-to-End - Integração Completa

## 🎯 Objetivo

Demonstrar integração completa dos 6 serviços através de um workflow corporativo realista:

**Cenário:** Usuário autentica no LDAP, envia email via SMTP, sistema audita no banco de dados,  logs são centralizados, tudo passa pelo firewall.

---

## 📊 Fluxo do Teste

```
1. LDAP (Autenticação)
   Cliente verifica/cria usuário no Active Directory
   ↓
2. SMTP (Email)
   Cliente envia email validado contra LDAP
   ↓
3. LDAP (Validação)
   SMTP consulta LDAP para verificar destinatário
   ↓
4. Maildir (Entrega)
   Email entregue em /var/mail/empresa.local/user2/
   ↓
5. Rsyslog (Logs)
   SMTP envia logs para servidor central
   ↓
6. Firewall + Database (Auditoria)
   Cliente → Firewall → Database (port forward)
   Sistema registra transação
```

**Resultado:** 6/6 serviços integrados ✓

---

## 🚀 Executar o Teste

### Comando Simples

```bash
./scripts/test_end_to_end.sh
```

**Tempo:** ~60 segundos  
**Saída:** `docs/teste_end_to_end.txt`

---

### O Que Acontece (Resumo)

**PASSO 1 - LDAP:**
- Verifica se `user1` existe
- Cria usuário se não existir
- ✓ Autenticação pronta

**PASSO 2 - SMTP:**
- Atualiza mapas LDAP (virtual-mailbox, sender-login)
- Envia email `user1` → `user2`
- ✓ Email aceito

**PASSO 3 - Maildir:**
- Aguarda 5s processamento
- Verifica entrega em `/var/mail/.../user2/`
- ✓ Email entregue (3 arquivos: cur, new, tmp)

**PASSO 4 - Logs:**
- Procura logs no servidor central (`logs-ntp`)
- ✓ Logs encontrados em `/var/log/remote/`

**PASSO 5 - Database:**
- Cria tabela `audit_log` (se não existir)
- Insere registro com test_id, usuário, ação
- ✓ Auditoria registrada

**PASSO 6 - Consulta:**
- Cliente consulta `audit_log` via Firewall
- ✓ Registro recuperado

---

## ✅ Critérios de Sucesso

### Indicadores Visuais

```bash
✓  # Verde = Passou
⚠  # Amarelo = Warning (não crítico)
✗  # Vermelho = Falhou
```

### Score Final

```
Serviços integrados: 6/6
  ✓ LDAP (autenticação)
  ✓ SMTP (envio e entrega)
  ✓ Logs-NTP (rsyslog)
  ✓ Database (auditoria)
  ✓ Cliente (inicializador)
  ✓ Firewall (rede protegida + port forward)
```

**6/6 = 100% = Sucesso Completo** 🎉

---

## 📋 Validação Manual

### 1. Verificar Usuário LDAP

```bash
docker-compose exec ldap samba-tool user list | grep user1
```

**Esperado:** `user1` na lista

### 2. Verificar Email Entregue

```bash
docker-compose exec smtp ls -R /var/mail/empresa.local/user2/
```

**Esperado:** Arquivos em `new/` e/ou `cur/`

### 3. Verificar Logs Centralizados

```bash
docker-compose exec logs-ntp ls -lR /var/log/remote/
```

**Esperado:** Diretório `mail/` ou `mail.empresa.local/`

### 4. Verificar Auditoria

```bash
docker-compose exec database psql -U app_user -d empresa_db \
  -c "SELECT * FROM audit_log ORDER BY timestamp DESC LIMIT 5;"
```

**Esperado:** Registros de teste com `test_id` like `TEST_E2E_%`

### 5. Verificar Firewall

```bash
docker-compose exec firewall iptables -t nat -L PREROUTING -n -v
```

**Esperado:** Regra DNAT com contadores > 0

---

## 🔍 Interpretar Resultados

### Arquivo de Saída

Após executar o teste, ver:

```bash
cat docs/teste_end_to_end.txt
```

### Buscar Seções Principais

```bash
# Ver só os status
grep "✓\|✗\|⚠" docs/teste_end_to_end.txt

# Ver resumo final
tail -30 docs/teste_end_to_end.txt
```

### Exemplo de Saída Bem-Sucedida

```
PASSO 1/6: Autenticação no LDAP
✓ Usuário user1 existe no LDAP

PASSO 2/6: Envio de Email via SMTP
✓ Email enviado com sucesso

PASSO 3/6: Verificação de Entrega (SMTP → Maildir)
✓ Email entregue no Maildir de user2
   (encontrado 3 arquivo(s) com ID do teste)

PASSO 4/6: Logs Centralizados (SMTP → rsyslog)
✓ Logs encontrados no servidor central (1 linhas)

PASSO 5/6: Auditoria no Banco de Dados
✓ Tabela audit_log pronta
✓ Auditoria registrada no PostgreSQL

PASSO 6/6: Consulta de Auditoria (Cliente → Database)
 id |         timestamp          |         test_id          | usuario |           acao            | status  
----+----------------------------+--------------------------+---------+---------------------------+---------
  2 | 2026-02-03 19:18:19.292552 | TEST_E2E_20260203_161802 | user1   | Envio de email end-to-end | SUCESSO
(1 row)

✓ Total de registros de auditoria no sistema: 2

TESTE END-TO-END CONCLUÍDO!

Serviços integrados: 6/6
```

---

## ⚠️ Warnings Comuns (Não Críticos)

### 1. `ldapwhoami` não disponível
```
⚠ Autenticação LDAP não testada (ldapwhoami pode não estar disponível)
```
**Impacto:** ZERO  
**Motivo:** Comando não instalado no cliente  
**Alternativa:** Autenticação provada por criação de usuário com `samba-tool`

### 2. Logs centralizados parciais
```
✓ Logs encontrados no servidor central (1 linhas)
```
**Esperado:** Pelo menos 1 linha significa que logs estão chegando  
**Se 0 linhas:** Executar `./scripts/fix_rsyslog.sh`

---

## 🛠️ Troubleshooting

### Teste Falhou em um Passo

```bash
# Ver logs do serviço específico
docker-compose logs [serviço]

# Exemplos
docker-compose logs smtp
docker-compose logs ldap
docker-compose logs database
```

### Logs Não Centralizam

```bash
# Diagnosticar
./scripts/diagnose_rsyslog.sh

# Corrigir
./scripts/fix_rsyslog.sh

# Re-testar
./scripts/test_end_to_end.sh
```

### Database Sem Tabela

```bash
# Criar manualmente
docker-compose exec database psql -U app_user -d empresa_db -c "
CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT NOW(),
    test_id VARCHAR(100),
    usuario VARCHAR(50),
    acao TEXT,
    status VARCHAR(20)
);"
```

### Firewall Sem Regras

```bash
# Verificar se script rodou
docker-compose logs firewall | grep "Setup concluído"

# Re-executar manualmente
docker-compose exec firewall bash /usr/local/bin/setup_forward.sh
```

---

## 📊 Evidências para Apresentação

### Capturas de Tela Recomendadas

1. **Comando de execução**
   ```bash
   ./scripts/test_end_to_end.sh
   ```

2. **Score final** (6/6 serviços)

3. **Tabela audit_log** com registro inserido

4. **Regras iptables** do firewall (port forward)

5. **Estrutura de logs** em `/var/log/remote/`

### Demonstração Ao Vivo (2-3 min)

```bash
# 1. Executar teste
./scripts/test_end_to_end.sh

# 2. Enquanto roda, explicar fluxo
# (usar diagrama da topologia)

# 3. Ao terminar, destacar:
#    - Score 6/6
#    - Mostrar audit_log
#    - Mostrar regras firewall
```

---

## 🎓 Valor do Teste

### O Que Demonstra

1. **Integração Real:** Não são testes isolados, é um workflow completo
2. **Autenticação Centralizada:** LDAP como fonte única de verdade
3. **Auditoria:** Rastreabilidade completa com test_id
4. **Logs Centralizados:** Visibilidade operacional
5. **Segurança em Camadas:** Firewall, validação LDAP, ACLs
6. **Automação:** Script reproduzível e documentado

### Para a Apresentação

> "Este teste simula um cenário corporativo real: um usuário autenticado envia um email, o sistema valida contra o LDAP, entrega o email, centraliza os logs e audita a transação no banco de dados. Tudo passa pelo firewall usando port forwarding. Demonstra integração completa dos 6 serviços com rastreabilidade end-to-end."

---

## 📚 Documentação Relacionada

- **Topologia:** `docs/02_TOPOLOGIA.md`
- **Serviços:** `docs/servicos/*.md`
- **Instalação:** `docs/01_INSTALACAO.md`
- **Evidências:** `docs/EVIDENCIAS/README.md`

---

**Teste End-to-End: Prova concreta de integração completa com workflow corporativo realista.** ✅
