# Guia do Teste End-to-End

Documentação objetiva do teste de integração completo dos 6 serviços.

---

## 1. Topologia do Teste

### Arquitetura dos Serviços

```
┌─────────────────────────────────────────────────────────────┐
│                     Rede Docker: 10.0.1.0/24                │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐
│   CLIENTE    │ 10.0.1.10 (Inicia o teste)
└──────┬───────┘
       │
       ├─────────────────┐
       │                 │
       ▼                 ▼
  ┌─────────┐      ┌─────────┐
  │  LDAP   │      │  SMTP   │ 10.0.1.30
  │10.0.1.20│      └────┬────┘
  └─────────┘           │
       ▲                │
       │                │
       │                ├──────────────┐
       │                │              │
       └────────────────┘              ▼
     (validação user)          ┌──────────────┐
                               │  LOGS-NTP    │ 10.0.1.50
                               │  (rsyslog)   │
                               └──────────────┘

                ┌──────────────┐
                │  FIREWALL    │ 10.0.1.60 (Rede protegida)
                └──────────────┘

                ┌──────────────┐
                │  DATABASE    │ 10.0.1.40
                │ (PostgreSQL) │
                └──────────────┘
```

### Comunicação no Teste

```
FLUXO COMPLETO:

1. CLIENTE → LDAP
   - Cria/verifica usuário user1
   - Porta: 389 (LDAP)

2. CLIENTE → SMTP
   - Envia email user1@empresa.local → user2@empresa.local
   - Porta: 25 (SMTP)

3. SMTP → LDAP
   - Valida remetente/destinatário
   - Consulta: virtual-mailbox-maps, sender-login-maps
   - Porta: 389

4. SMTP → MAILDIR LOCAL
   - Entrega email em /var/mail/empresa.local/user2/

5. SMTP → LOGS-NTP
   - Envia logs via rsyslog
   - Protocolo: UDP porta 514

6. CLIENTE → DATABASE
   - Insere auditoria (test_id, usuário, ação)
   - Consulta auditoria
   - Porta: 5432 (PostgreSQL)
```

### Portas Utilizadas

| Serviço | Container | IP | Porta | Protocolo |
|---------|-----------|----|----|-----------|
| LDAP | ldap | 10.0.1.20 | 389 | TCP |
| SMTP | smtp | 10.0.1.30 | 25 | TCP |
| rsyslog | logs-ntp | 10.0.1.50 | 514 | UDP |
| PostgreSQL | database | 10.0.1.40 | 5432 | TCP |
| Firewall | firewall | 10.0.1.60 | - | - |

---

## 2. Passo a Passo do Teste

### Execução

```bash
./scripts/test_end_to_end.sh
```

### O Que o Script Faz

#### PASSO 1: Autenticação LDAP
**Objetivo:** Garantir que usuário existe no Active Directory

**Comandos:**
```bash
# Verifica se user1 existe
docker-compose exec ldap samba-tool user list | grep user1

# Se não existir, cria
docker-compose exec ldap samba-tool user create user1 SenhaForte123!
```

**Sucesso:** Usuário disponível para autenticação

---

#### PASSO 2: Envio de Email
**Objetivo:** Enviar email validado contra LDAP

**Comandos:**
```bash
# 1. Atualizar mapas LDAP do Postfix
docker-compose exec smtp /scripts/update_ldap_maps.sh

# 2. Enviar email
docker-compose exec smtp sendmail user2@empresa.local <<EOF
From: user1@empresa.local
To: user2@empresa.local
Subject: Test E2E ${TEST_ID}

Teste de integração completa.
EOF
```

**Sucesso:** Email aceito pelo Postfix

---

#### PASSO 3: Verificação de Entrega
**Objetivo:** Confirmar que email chegou ao Maildir

**Comandos:**
```bash
# Aguardar 5s processamento
sleep 5

# Procurar email no Maildir de user2
docker-compose exec smtp find /var/mail/empresa.local/user2/ -type f -exec grep -l "${TEST_ID}" {} \;
```

**Sucesso:** Encontra 1+ arquivo com o TEST_ID

---

#### PASSO 4: Logs Centralizados
**Objetivo:** Verificar se logs do SMTP chegaram ao servidor central

**Comandos:**
```bash
# Procurar logs do teste no servidor logs-ntp
docker-compose exec logs-ntp grep -r "${TEST_ID}" /var/log/remote/

# Verificar logs locais (backup)
docker-compose exec smtp tail -5 /var/log/mail.log
```

**Sucesso:** Logs encontrados em `/var/log/remote/`

---

#### PASSO 5: Auditoria no Banco
**Objetivo:** Registrar transação no PostgreSQL

**Comandos:**
```bash
# Criar tabela (se não existir)
docker-compose exec database psql -U app_user -d empresa_db -c "
CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT NOW(),
    test_id VARCHAR(100),
    usuario VARCHAR(50),
    acao TEXT,
    status VARCHAR(20)
);"

# Inserir registro
docker-compose exec database psql -U app_user -d empresa_db -c "
INSERT INTO audit_log (test_id, usuario, acao, status)
VALUES ('${TEST_ID}', 'user1', 'Envio de email end-to-end', 'SUCESSO');"
```

**Sucesso:** INSERT retorna "INSERT 0 1"

---

#### PASSO 6: Consulta de Auditoria
**Objetivo:** Cliente recupera dados de auditoria

**Comandos:**
```bash
# Consultar registro específico
docker-compose exec database psql -U app_user -d empresa_db -c "
SELECT * FROM audit_log WHERE test_id = '${TEST_ID}';"

# Contar total de auditorias
docker-compose exec database psql -U app_user -d empresa_db -c "
SELECT COUNT(*) FROM audit_log;"
```

**Sucesso:** Query retorna o registro inserido

---

## 3. Como Ver e Interpretar Resultados

### Resultado Salvo Automaticamente

```bash
# Ver último resultado
cat docs/teste_end_to_end.txt
```

### Interpretar Status

#### ✅ Símbolo Verde = Sucesso
```
✓ Email entregue no Maildir de user2
✓ Logs encontrados no servidor central (X linhas)
✓ Auditoria registrada no PostgreSQL
```
**Significado:** Passo passou completamente

---

#### ⚠️ Símbolo Amarelo = Warning (Não Crítico)
```
⚠ Usuário user1 não encontrado no LDAP
  Criando usuário para teste...
```
**Significado:** Comportamento normal, script resolve automaticamente

---

#### ✗ Símbolo Vermelho = Erro
```
✗ Email NÃO foi entregue
```
**Significado:** Passo falhou, investigar logs

---

### Score Final

No final do teste, procurar por:

```
Serviços integrados: 6/6
  • LDAP (autenticação)
  • SMTP (envio e entrega)
  • Logs-NTP (rsyslog)
  • Database (auditoria)
  • Cliente (inicializador)
  • Firewall (rede protegida)
```

**6/6 = 100% = Sucesso Completo**

---

### Checklist de Validação

| Passo | Indicador de Sucesso | Como Verificar |
|-------|----------------------|----------------|
| **1. LDAP** | "Usuário user1 existe" ou "Criando usuário" | `samba-tool user list` |
| **2. SMTP** | "✓ Email enviado com sucesso" | Saída do sendmail sem erro |
| **3. Maildir** | "✓ Email entregue no Maildir" | `find /var/mail/.../user2/` |
| **4. Logs** | "✓ Logs encontrados no servidor central" | `grep -r TEST_ID /var/log/remote/` |
| **5. Audit** | "✓ Auditoria registrada" | `INSERT 0 1` |
| **6. Query** | Tabela com linha do teste | `SELECT` retorna 1+ linhas |

---

### Comandos Úteis para Apresentação

#### Ver ID do Último Teste
```bash
grep "ID do Teste:" docs/teste_end_to_end.txt
```

#### Consultar Auditoria Manualmente
```bash
docker-compose exec database psql -U app_user -d empresa_db -c "SELECT * FROM audit_log ORDER BY timestamp DESC LIMIT 5;"
```

#### Ver Logs Centralizados
```bash
docker-compose exec logs-ntp ls -lR /var/log/remote/
docker-compose exec logs-ntp tail -20 /var/log/remote/mail/all.log
```

#### Ver Maildirs Criados
```bash
docker-compose exec smtp ls -lR /var/mail/empresa.local/
```

---

## 4. Dificuldades e Soluções

### Dificuldade 1: Logs Não Chegavam ao Servidor Central

**Sintoma:**
```
⚠️ Logs centralizados funcionam parcialmente (local OK, central não encontrado)
```

**Causa Raiz:**
- rsyslog no **logs-ntp** não estava configurado para receber UDP:514
- rsyslog no **smtp** não estava configurado para enviar logs

**Solução Implementada:**
```bash
# 1. Diagnosticar
./scripts/diagnose_rsyslog.sh

# 2. Corrigir automaticamente
./scripts/fix_rsyslog.sh
```

**Configuração Aplicada:**

*No servidor (logs-ntp):*
```conf
# /etc/rsyslog.d/00-remote.conf
module(load="imudp")
input(type="imudp" port="514")
$template RemoteHost,"/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteHost
```

*No cliente (smtp):*
```conf
# /etc/rsyslog.d/50-forward.conf
*.* @logs-ntp:514
```

**Resultado:** Logs agora chegam em `/var/log/remote/mail/`

**Documentação:** `docs/RSYSLOG_CENTRALIZADO.md`

---

### Dificuldade 2: SMTP Não Iniciava (Erro em main.cf)

**Sintoma:**
```
fatal: in master_smtpd_relay_restrictions
bad command startup -- throttling
```

**Causa Raiz:**
- Diretiva `smtpd_relay_restrictions` faltando no `main.cf` (obrigatória no Postfix moderno)

**Solução:**
```conf
# Adicionado em docker/smtp/main.cf
smtpd_relay_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination
```

**Resultado:** SMTP inicia em ~20s

---

### Dificuldade 3: Validação LDAP de Usuários

**Sintoma:**
- Postfix aceitava emails de usuários inexistentes

**Causa Raiz:**
- Mapas LDAP (virtual-mailbox-maps, sender-login-maps) não atualizados

**Solução:**
```bash
# Script criado: docker/smtp/scripts/update_ldap_maps.sh
# Atualiza mapas LDAP dinamicamente e gera arquivos .hash.db
```

**Integrado no teste:** PASSO 2.1

---

### Dificuldade 4: Firewall Não Filtra Tráfego Inter-Container

**Sintoma:**
- Containers comunicam diretamente via rede Docker, bypass do firewall

**Causa Raiz:**
- Arquitetura do Docker: tráfego inter-container na mesma rede bridge não passa pelo container firewall

**Solução (Arquitetural):**
- **Limitação aceita e documentada**
- Container firewall protege entrada/saída do host
- Em produção: usar Network Policies (Kubernetes) ou Service Mesh

**Documentação:** `docs/FIREWALL_DOCKER.md`

**Para apresentação:**
> "O firewall protege entrada no host, mas tráfego entre containers na mesma rede Docker não passa por ele - isso é uma limitação arquitetural do Docker. Em produção real, usaríamos Kubernetes Network Policies ou Service Mesh como Istio."

---

### Dificuldade 5: ClamAV/Amavis Atrasava Startup em 135s

**Sintoma:**
- Container SMTP demorava 135s+ para ficar pronto

**Causa Raiz:**
- ClamAV carrega 400 MB de assinaturas, consumia 800 MB RAM

**Solução:**
- **Desativado ClamAV/Amavis**
- Justificativa: múltiplas camadas de defesa (firewall, SpamAssassin, ACLs)
- Startup reduzido para ~20s (-85%)

**Documentação:** `docs/OPCAO_SEM_ANTIVIRUS.md`

---

### Dificuldade 6: Warnings do rsyslog Durante Startup

**Sintoma:**
```
rsyslogd: module 'imudp' already in this config, cannot be added
rsyslogd: imklog: cannot open kernel log
```

**Causa Raiz:**
- Módulo duplicado em múltiplas configurações
- Containers não têm acesso ao kernel log do host

**Impacto:**
- **ZERO** - Warnings cosméticos, funcionalidade não afetada

**Solução:**
- Ignorar (não crítico)
- Opcional: limpar `/etc/rsyslog.conf` base no Dockerfile

---

### Dificuldade 7: ldapwhoami Não Disponível

**Sintoma:**
```
⚠ Autenticação LDAP não testada (ldapwhoami pode não estar disponível)
```

**Causa Raiz:**
- Comando `ldapwhoami` não instalado no container cliente

**Impacto:**
- **BAIXO** - Autenticação LDAP validada por outros meios (usuário criado, SMTP consulta LDAP)

**Solução:**
- Warning aceito como não-crítico
- Alternativa: usar `ldapsearch` (já disponível)

---

### Resumo de Dificuldades

| # | Problema | Criticidade | Status |
|---|----------|-------------|--------|
| 1 | Logs não centralizados | 🔴 Alta | ✅ **Resolvido** |
| 2 | SMTP erro main.cf | 🔴 Alta | ✅ **Resolvido** |
| 3 | Validação LDAP | 🟡 Média | ✅ **Resolvido** |
| 4 | Firewall bypass | 🟡 Média | 📝 **Documentado** |
| 5 | ClamAV lento | 🟡 Média | ✅ **Removido** |
| 6 | Warnings rsyslog | 🟢 Baixa | ✅ **Ignorado** |
| 7 | ldapwhoami | 🟢 Baixa | ✅ **Ignorado** |

**Todos os problemas críticos resolvidos! 🎉**

---

## Comandos Rápidos (Resumo)

```bash
# Executar teste completo
./scripts/test_end_to_end.sh

# Ver resultado
cat docs/teste_end_to_end.txt

# Diagnosticar logs (se necessário)
./scripts/diagnose_rsyslog.sh

# Corrigir logs (se necessário)
./scripts/fix_rsyslog.sh

# Ver auditoria no banco
docker-compose exec database psql -U app_user -d empresa_db -c "SELECT * FROM audit_log ORDER BY timestamp DESC LIMIT 5;"

# Ver logs centralizados
docker-compose exec logs-ntp tail -20 /var/log/remote/mail/all.log

# Ver estrutura de logs
docker-compose exec logs-ntp tree /var/log/remote/
```

---

## Para a Apresentação

### Demonstração Sugerida

1. **Mostrar topologia** (seção 1)
2. **Executar teste:** `./scripts/test_end_to_end.sh`
3. **Mostrar resultado:** `cat docs/teste_end_to_end.txt`
4. **Destacar score:** "6/6 serviços integrados"
5. **Mostrar auditoria:** Query no PostgreSQL
6. **Mostrar logs centralizados:** `tail -f /var/log/remote/...`

### Se Perguntarem sobre Dificuldades

**Use a seção 4 como referência!** Cada dificuldade tem:
- Sintoma claro
- Causa raiz identificada
- Solução implementada
- Status atual

**Exemplo:**
> "A principal dificuldade foi configurar logs centralizados. O rsyslog precisava ser configurado em dois pontos: servidor para receber UDP:514 e cliente para enviar. Criei scripts de diagnóstico e correção automática que resolveram o problema."

---

**Fim do Guia**
