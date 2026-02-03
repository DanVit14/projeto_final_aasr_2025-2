# Topologia da Rede e Arquitetura do Sistema

## 📊 Visão Geral

Sistema de infraestrutura corporativa com 6 serviços integrados em rede Docker isolada.

**Rede:** `10.0.1.0/24` (aasr_net)

---

## 🗺️ Diagrama da Topologia

```
┌─────────────────────────────────────────────────────────────┐
│                   Rede Docker: 10.0.1.0/24                   │
│                        (aasr_net)                            │
└─────────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │   CLIENTE    │ 10.0.1.60
                    │  (Testes)    │
                    └──────┬───────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ FIREWALL │    │   LDAP   │    │   SMTP   │
    │10.0.1.20 │    │10.0.1.30 │    │10.0.1.30 │
    └────┬─────┘    └────┬─────┘    └────┬─────┘
         │               │               │
         │ (Port Fwd)    │               │
         │               │               ├─────────┐
         ▼               ▼               ▼         │
    ┌──────────┐    (Auth/Valid)   ┌──────────┐  │
    │ DATABASE │                    │LOGS-NTP  │  │
    │10.0.1.40 │◄───────────────────│10.0.1.50 │◄─┘
    │PostgreSQL│      (Auditoria)   │ Rsyslog  │
    └──────────┘                    │   NTP    │
                                    └──────────┘
```

---

## 🔄 Fluxos de Comunicação

### 1. Autenticação (LDAP)
```
Cliente → LDAP:389
  └─ Verifica/cria usuários
  └─ Valida credenciais
  └─ Fornece dados para SMTP
```

### 2. Email (SMTP)
```
Cliente → SMTP:25
  └─ Envia email
      ├─ Valida contra LDAP
      ├─ Entrega em Maildir
      └─ Envia logs para Logs-NTP
```

### 3. Port Forwarding (Firewall)
```
Cliente → Firewall:5432 → Database:5432
  └─ DNAT (redirecionamento)
  └─ MASQUERADE (NAT origem)
  └─ LOG (registro de conexões)
```

### 4. Logs Centralizados (Rsyslog)
```
SMTP → Logs-NTP:514/udp
Cliente → Logs-NTP:514/udp
  └─ Organiza por hostname em /var/log/remote/
```

### 5. Sincronização de Tempo (NTP)
```
Containers → Logs-NTP:123/udp
  └─ Sincroniza relógios
```

### 6. Auditoria (PostgreSQL)
```
Cliente → Firewall → Database:5432
  └─ Insere registros na tabela audit_log
  └─ Consulta histórico
```

---

## 🏗️ Arquitetura de Serviços

### Container 1: Firewall
**IP:** 10.0.1.20  
**Imagem:** Debian 11 + iptables  
**Função:** 
- Firewall de rede (limitado a tráfego do host)
- Port forwarding PostgreSQL (DNAT)
- Logging de conexões

**Portas Expostas:**
- `2222:22` (SSH no host)
- `5433:5432` (PostgreSQL via firewall no host)

**Limitação:** Tráfego inter-container Docker não passa pelo firewall (arquitetura Docker). Solução: Port forwarding explícito via NAT.

---

### Container 2: LDAP (Samba AD DC)
**IP:** 10.0.1.30  
**Imagem:** Debian 11 + Samba 4  
**Função:**
- Active Directory Domain Controller
- Autenticação de usuários
- Validação para SMTP

**Domínio:** empresa.local  
**Usuários de Teste:** user1, user2, user3, admin

**Portas:**
- `389` (LDAP)
- `636` (LDAPS)
- `88` (Kerberos)

---

### Container 3: SMTP (Postfix + Dovecot)
**IP:** 10.0.1.30  
**Imagem:** Debian 11 + Postfix + Dovecot + SpamAssassin  
**Função:**
- Servidor de email (envio e entrega)
- Integração LDAP (validação usuários)
- Antispam (SpamAssassin)
- Logs para servidor central

**Portas Expostas:**
- `2525:25` (SMTP no host)

**Configurações:**
- Maildir: `/var/mail/empresa.local/[usuario]/`
- LDAP maps: virtual-mailbox, sender-login
- Sem chroot (acesso a LDAP)

**Nota:** ClamAV desativado (motivo: startup lento, documentado em `servicos/SMTP.md`)

---

### Container 4: Database (PostgreSQL)
**IP:** 10.0.1.40  
**Imagem:** PostgreSQL 15  
**Função:**
- Banco de dados corporativo
- Auditoria de transações (tabela `audit_log`)
- Backup/Restore

**Portas Expostas:**
- `5432:5432` (Acesso direto no host)

**Database:** `empresa_db`  
**User:** `app_user`  
**Volumes:** Persistência em `postgres_data`

---

### Container 5: Logs-NTP (Rsyslog + Chrony)
**IP:** 10.0.1.50  
**Imagem:** Debian 11 + Rsyslog + Chrony  
**Função:**
- Servidor rsyslog centralizado (UDP:514)
- Servidor NTP (UDP:123)
- Organiza logs por hostname

**Portas Expostas:**
- `123:123/udp` (NTP no host)

**Logs:** `/var/log/remote/[hostname]/[programa].log`

---

### Container 6: Cliente (Teste)
**IP:** 10.0.1.60  
**Imagem:** Debian 11 + ferramentas  
**Função:**
- Executar testes de integração
- Simular cliente corporativo
- Iniciar workflows end-to-end

**Ferramentas:** psql, ldap-utils, sendmail, netcat

---

## 🌐 Tabela de Endereçamento

| Serviço | Container | IP | Porta Interna | Porta Host | Protocolo |
|---------|-----------|---------|---------------|------------|-----------|
| Firewall SSH | firewall | 10.0.1.20 | 22 | 2222 | TCP |
| Firewall→DB | firewall | 10.0.1.20 | 5432→10.0.1.40 | 5433 | TCP |
| LDAP | ldap | 10.0.1.30 | 389 | - | TCP |
| SMTP | smtp | 10.0.1.30 | 25 | 2525 | TCP |
| PostgreSQL | database | 10.0.1.40 | 5432 | 5432 | TCP |
| Rsyslog | logs-ntp | 10.0.1.50 | 514 | - | UDP |
| NTP | logs-ntp | 10.0.1.50 | 123 | 123 | UDP |
| Cliente | cliente | 10.0.1.60 | - | - | - |

---

## 🔐 Decisões de Design

### 1. Rede Isolada
**Decisão:** Usar rede Docker customizada (`aasr_net`)  
**Motivo:** Isolamento, controle de IPs, comunicação por hostname  
**Vantagem:** Ambiente reproduzível, sem conflito com rede do host

### 2. IPs Estáticos
**Decisão:** Atribuir IPs fixos (10.0.1.X)  
**Motivo:** Facilitar configuração, debugging e demonstração  
**Vantagem:** Documentação clara, troubleshooting simples

### 3. Portas Alternativas no Host
**Decisão:** 
- SSH: 2222 (em vez de 22)
- SMTP: 2525 (em vez de 25)
- Firewall→DB: 5433 (em vez de 5432)

**Motivo:** Evitar conflito com serviços do host  
**Vantagem:** Coexistência com outros serviços

### 4. Firewall com Port Forwarding
**Decisão:** Implementar DNAT para PostgreSQL  
**Motivo:** Integrar firewall no fluxo (limitação: tráfego inter-container não passa pelo firewall em Docker padrão)  
**Alternativa Produção:** Kubernetes Network Policies, Service Mesh

### 5. Logs Centralizados
**Decisão:** Rsyslog em container dedicado  
**Motivo:** Centralização, auditoria, facilita troubleshooting  
**Implementação:** UDP:514, organização por hostname

### 6. LDAP Integrado ao SMTP
**Decisão:** Postfix valida usuários contra LDAP  
**Motivo:** Autenticação centralizada, evitar spam relay  
**Implementação:** Maps LDAP (virtual-mailbox, sender-login)

### 7. Sem Antivírus
**Decisão:** Desativar ClamAV  
**Motivo:** Startup lento (135s → 20s), recurso intensivo  
**Justificativa:** Múltiplas camadas de defesa (firewall, SpamAssassin, ACLs)  
**Documentação:** `servicos/SMTP.md`

---

## 📈 Escalabilidade e Produção

### Limitações Atuais (Ambiente de Testes)

1. **Firewall:** Não filtra tráfego inter-container
   - **Solução Produção:** Kubernetes Network Policies

2. **Volumes:** Dados em volumes Docker locais
   - **Solução Produção:** NFS, Ceph, AWS EBS

3. **Alta Disponibilidade:** Sem replicação
   - **Solução Produção:** PostgreSQL replication, SMTP clusters

4. **Monitoramento:** Logs básicos
   - **Solução Produção:** Prometheus, Grafana, ELK Stack

### Evolução para Produção

```
Docker Compose (Dev/Test)
    ↓
Docker Swarm (HA básico)
    ↓
Kubernetes (Produção completa)
    ├─ Ingress Controller (substituiFirewall)
    ├─ Network Policies (segmentação real)
    ├─ StatefulSets (bancos de dados)
    ├─ ConfigMaps/Secrets (configuração)
    └─ Monitoring (Prometheus/Grafana)
```

---

## 🎯 Fluxo End-to-End Completo

Ver detalhes em `docs/03_TESTE_E2E.md`

```
1. Cliente → LDAP
   └─ Autentica usuário

2. Cliente → SMTP
   └─ Envia email

3. SMTP → LDAP
   └─ Valida destinatário

4. SMTP → Maildir
   └─ Entrega email

5. SMTP → Logs-NTP
   └─ Envia logs (rsyslog)

6. Cliente → Firewall → Database
   └─ Registra auditoria
   └─ Consulta histórico

✓ 6/6 serviços integrados
```

---

## 📚 Documentação Relacionada

- **Serviços:** `docs/servicos/*.md`
- **Teste E2E:** `docs/03_TESTE_E2E.md`
- **Instalação:** `docs/01_INSTALACAO.md`
- **Evidências:** `docs/EVIDENCIAS/README.md`

---

**Topologia projetada para demonstrar integração completa de serviços em ambiente corporativo simulado.** ✅
