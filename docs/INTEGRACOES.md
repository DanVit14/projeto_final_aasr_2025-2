# Integrações Entre Serviços

Este documento descreve as **integrações reais** entre os serviços da infraestrutura, não apenas conectividade.

---

## 📊 Mapa de Integrações

```
┌─────────────────────────────────────────────────────────────────┐
│                   Integrações Implementadas                      │
└─────────────────────────────────────────────────────────────────┘

                    ┌────────────┐
                    │  LOGS-NTP  │ ← Serviço base (NTP + rsyslog)
                    │ 10.0.1.50  │
                    └──────┬─────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
   ┌─────────┐        ┌─────────┐       ┌──────────┐
   │  LDAP   │◄───────┤  SMTP   │       │ Firewall │
   │10.0.1.10│        │10.0.1.30│       │10.0.1.20 │
   └─────────┘        └─────────┘       └──────────┘
        ▲                  │
        │                  │ (logs)
        │                  ▼
        │             ┌─────────┐
        │             │logs-ntp │
        │             └─────────┘
        │
   (contas virtuais)
        │
   ┌─────────┐
   │Database │ ← Standalone (sem integração)
   │10.0.1.40│
   └─────────┘
```

---

## 🔗 Integrações Implementadas

### 1. SMTP ↔ LDAP (Crítico!) ✅

**Tipo:** Autenticação e contas virtuais

**Configuração:**
```conf
# docker/smtp/main.cf
virtual_mailbox_domains = empresa.local
virtual_mailbox_base = /var/mail/vhosts
virtual_mailbox_maps = hash:/etc/postfix/ldap/virtual-mailbox-maps.hash
virtual_alias_maps = hash:/etc/postfix/ldap/virtual-alias-maps.hash
smtpd_sender_login_maps = hash:/etc/postfix/ldap/sender-login-maps.hash
```

**Fluxo:**
1. LDAP mantém usuários (user1, user2, admin)
2. Script `update-ldap-maps.sh` query LDAP e gera hashes
3. Postfix consulta hashes para:
   - Validar remetentes (`smtpd_sender_login_maps`)
   - Mapear destinatários (`virtual_mailbox_maps`)
   - Resolver aliases (`virtual_alias_maps`)

**Teste de Integração:**
```bash
# Verifica se user1 existe no LDAP
ldapsearch -x -H ldap://ldap -b "dc=empresa,dc=local" "(cn=user1)"

# Envia email como user1 (deve aceitar)
echo "Subject: Teste" | sendmail -f user1@empresa.local user2@empresa.local

# Verifica Maildir criado via LDAP integration
ls /var/mail/vhosts/empresa.local/user1/Maildir/
```

**Ver:** `scripts/test_integrations.sh` (Teste 1)

---

### 2. Todos os Serviços → Logs-NTP (rsyslog) ✅

**Tipo:** Centralização de logs

**Configuração:**
```conf
# Cada container com rsyslog-forward.conf
*.* @logs-ntp:514
```

**Fluxo:**
1. SMTP, Firewall, etc. enviam logs via UDP:514
2. Container `logs-ntp` recebe em `/var/log/`
3. Logs organizados por hostname

**Teste de Integração:**
```bash
# Enviar log de teste
logger -n logs-ntp -P 514 "TESTE_INTEGRACAO"

# Verificar no servidor central
docker-compose exec logs-ntp grep "TESTE_INTEGRACAO" /var/log/messages
```

**Ver:** `scripts/test_integrations.sh` (Teste 2)

---

### 3. Logs-NTP → Outros Containers (chrony) ✅

**Tipo:** Sincronização de tempo

**Configuração:**
```conf
# docker/logs-ntp/chrony.conf
server a.ntp.br iburst
server b.ntp.br iburst
server c.ntp.br iburst
allow 10.0.1.0/24
```

**Fluxo:**
1. Container `logs-ntp` sincroniza com servidores NTP brasileiros
2. Outros containers podem consultar logs-ntp:123 (NTP)
3. Docker gerencia sincronização de relógios automaticamente

**Teste de Integração:**
```bash
# Ver sincronização no servidor
docker-compose exec logs-ntp chronyc tracking

# Comparar timestamps entre containers
date +%s  # em cada container
```

**Ver:** `scripts/test_integrations.sh` (Teste 3)

---

## ❌ Integrações NÃO Implementadas

### 1. Database ↔ LDAP

**Não implementado** porque:
- PostgreSQL não precisa autenticar contra LDAP diretamente
- Aplicações que usam o DB fariam a bridge (ex: aplicação web)
- Database é standalone neste projeto

**Como implementar (se necessário):**
```conf
# postgresql.conf
# Instalar postgresql-ldap
# Configurar pg_hba.conf com LDAP auth
host    all    all    10.0.1.0/24    ldap ldapserver=ldap ldapbasedn="dc=empresa,dc=local"
```

### 2. Firewall ↔ Outros Containers

**Não implementado** porque:
- Tráfego inter-container não passa pelo container firewall
- Docker gerencia roteamento via bridge gateway
- Limitação arquitetural documentada

**Ver:** `docs/FIREWALL_DOCKER.md`

### 3. Samba/CIFS ↔ SMTP

**Não implementado** porque:
- Não há caso de uso (SMTP não precisa compartilhamentos SMB)
- Ambos usam LDAP, mas independentemente

---

## 🧪 Testes de Integração

### Script Automatizado

`scripts/test_integrations.sh` valida:

| Integração | Teste | Status |
|-----------|-------|--------|
| SMTP → LDAP | Verifica mapas hash, envia como user LDAP | ✅ |
| Services → rsyslog | Envia log, verifica chegada | ✅ |
| chrony → Containers | Compara timestamps | ✅ |
| DNS interno | Resolve hostnames entre containers | ✅ |

### Executar

```bash
# Apenas integração
./scripts/test_integrations.sh

# Tudo (conectividade + integração)
./scripts/run_all_tests.sh
```

---

## 📈 Níveis de Teste

### Nível 1: Conectividade (test_services.sh)
- ✓ Verifica se serviços **respondem**
- ✗ Não valida **comunicação real**

### Nível 2: Funcionalidade (test_smtp_completo.sh, test_crud_db.sh)
- ✓ Verifica se serviços **funcionam isoladamente**
- ✗ Não valida **integração**

### Nível 3: Integração (test_integrations.sh) ← **NOVO!**
- ✓ Valida **comunicação real** entre serviços
- ✓ Testa dependências (LDAP → SMTP)
- ✓ Verifica logs centralizados

---

## 🎯 Para a Apresentação

### Pergunta: "Os serviços integram entre si?"

**Resposta:**
> "Sim! Implementei 3 integrações reais:
> 1. **SMTP-LDAP**: Postfix valida contas virtuais contra o Samba AD
> 2. **Rsyslog centralizado**: Todos os containers enviam logs para logs-ntp
> 3. **Sincronização NTP**: chrony mantém relógios sincronizados
> 
> Criei o script `test_integrations.sh` que valida essas comunicações reais, não apenas conectividade. Database é standalone neste projeto."

### Demonstração Ao Vivo

```bash
# Executar testes de integração
./scripts/test_integrations.sh

# Mostrar mapa SMTP-LDAP
docker-compose exec smtp cat /etc/postfix/ldap/virtual-mailbox-maps.hash

# Mostrar logs centralizados
docker-compose exec logs-ntp tail -20 /var/log/remote/*.log
```

---

## 📚 Referências

- **TOPOLOGIA.md** - Diagrama de rede
- **DECISOES_TECNICAS.md** - Decisões de implementação
- **test_integrations.sh** - Script de validação

---

**Conclusão:** O projeto não apenas implementa serviços isolados, mas **integra-os funcionalmente** através de LDAP, rsyslog centralizado e sincronização NTP. Database é standalone por design (aplicações fariam a bridge).
