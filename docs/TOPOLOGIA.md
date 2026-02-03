# Topologia de Rede - Infraestrutura Corporativa AASR

## 📊 Visão Geral

Infraestrutura corporativa distribuída em 6 containers Docker, conectados por rede privada isolada (`aasr_net`).

## 🌐 Diagrama de Rede

```
                    ┌─────────────────────────────────────────┐
                    │         HOST (VM Debian 12)             │
                    │                                         │
                    │  Portas Expostas:                       │
                    │  • 2222:22   → firewall (SSH)           │
                    │  • 2525:25   → smtp (SMTP)              │
                    │  • 587:587   → smtp (Submission)        │
                    │  • 993:993   → smtp (IMAPS)             │
                    │  • 5432:5432 → database (PostgreSQL)    │
                    │  • 445:445   → ldap (SMB/CIFS)          │
                    └─────────────────────────────────────────┘
                                     │
                    ┌────────────────┴────────────────────────┐
                    │    Docker Network: aasr_net             │
                    │    Subnet: 10.0.1.0/24                  │
                    │    Gateway: 10.0.1.1                    │
                    └─────────────────────────────────────────┘
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        │                            │                            │
   ┌────▼────┐                  ┌────▼────┐                 ┌────▼────┐
   │  LDAP   │                  │Firewall │                 │  SMTP   │
   │10.0.1.10│                  │10.0.1.20│                 │10.0.1.30│
   └─────────┘                  └─────────┘                 └─────────┘
    • Samba AD                   • iptables                  • Postfix
    • LDAP                       • Netfilter                 • Dovecot
    • Kerberos                   • SSH                       • SpamAssassin
    • SMB/CIFS                   • Logging                   • Maildir
        │                            │                            │
        └────────────────────────────┼────────────────────────────┘
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        │                            │                            │
   ┌────▼────┐                  ┌────▼────┐                 ┌────▼────┐
   │Database │                  │Logs-NTP │                 │ Cliente │
   │10.0.1.40│                  │10.0.1.50│                 │10.0.1.60│
   └─────────┘                  └─────────┘                 └─────────┘
   • PostgreSQL 15              • rsyslog                    • Testes
   • CRUD + Backup              • chrony (NTP)              • Diagnóstico
   • Restore                    • Log Central               • Validação
```

## 🖥️ Containers e Endereçamento

| Container | Hostname | IP | Serviços | Portas |
|-----------|----------|---------|----------|--------|
| **ldap** | ldap.empresa.local | 10.0.1.10 | Samba AD, LDAP, Kerberos, SMB | 389, 636, 445, 139 |
| **firewall** | firewall.empresa.local | 10.0.1.20 | iptables, Netfilter, SSH | 22 (→2222) |
| **smtp** | mail.empresa.local | 10.0.1.30 | Postfix, Dovecot, SpamAssassin | 25 (→2525), 587, 993, 995 |
| **database** | db.empresa.local | 10.0.1.40 | PostgreSQL 15 | 5432 |
| **logs-ntp** | logs.empresa.local | 10.0.1.50 | rsyslog, chrony | 514 (UDP), 123 (UDP) |
| **cliente** | cliente.empresa.local | 10.0.1.60 | Cliente de teste | - |

## 📡 Fluxo de Comunicação

### 1. Autenticação (LDAP)
```
Cliente/SMTP → LDAP (10.0.1.10:389) → Validação de credenciais
```

### 2. Email (SMTP)
```
Cliente → SMTP (10.0.1.30:25) → Verificação LDAP → Antispam → Maildir
```

### 3. Banco de Dados
```
Aplicações → PostgreSQL (10.0.1.40:5432) → CRUD + Backup
```

### 4. Logs Centralizados
```
Todos os containers → rsyslog (10.0.1.50:514/UDP) → /var/log/remote/
```

### 5. Sincronização de Tempo
```
Todos os containers → chrony (10.0.1.50:123/UDP) → NTP sync
```

### 6. Firewall
```
Todas as comunicações → iptables (10.0.1.20) → Filtro + Log
```

## 🔒 Segurança

### Rede Isolada
- **Subnet privada**: 10.0.1.0/24
- **Sem acesso direto** da Internet
- **Portas expostas** apenas o necessário no host

### Firewall (iptables)
- **INPUT**: DROP por default
- **FORWARD**: Controle de tráfego entre containers
- **OUTPUT**: Permitido (com logging)
- **Logging**: Ações suspeitas registradas

### ACLs
- **Permissões granulares** por usuário/grupo
- **Máscaras** de permissões efetivas
- **Default ACLs** para herança

### LDAP/Kerberos
- **Autenticação centralizada**
- **TLS/SSL** para conexões seguras
- **Integração** com SMTP e Samba

## 📦 Volumes Persistentes

| Volume | Montagem | Descrição |
|--------|----------|-----------|
| `ldap_data` | `/var/lib/samba` | Dados do Samba AD/LDAP |
| `postgres_data` | `/var/lib/postgresql/data` | Banco de dados PostgreSQL |
| `mail_data` | `/var/mail` | Maildirs dos usuários |
| `./backups` | `/backups` | Backups do banco de dados |

## 🔧 Dependências de Inicialização

```
ldap (primeira inicialização)
  ↓
firewall, logs-ntp
  ↓
database, smtp (dependem de LDAP)
  ↓
cliente (depende de todos)
```

## 📝 Configurações de Rede

### DNS Interno
- **Domínio**: `empresa.local`
- **Resolução**: Docker DNS interno (127.0.0.11)
- **Hosts**: Definidos no `docker-compose.yml`

### Roteamento
- **Gateway padrão**: 10.0.1.1 (Docker bridge)
- **Comunicação interna**: Direto entre containers
- **Acesso externo**: Através de portas mapeadas no host

## 🚀 Comandos de Rede

### Ver estado da rede
```bash
docker network inspect aasr_net
```

### Testar conectividade
```bash
docker-compose exec cliente ping -c 3 ldap
docker-compose exec cliente ping -c 3 smtp
docker-compose exec cliente ping -c 3 database
```

### Ver portas escutando
```bash
docker-compose exec smtp ss -tlnp
docker-compose exec database ss -tlnp
```

## 📊 Métricas de Desempenho

- **Latência interna**: <1ms (rede Docker)
- **Throughput**: ~10 Gbps (limitado pela rede virtual)
- **Startup time**: ~30-45s (todos os serviços)
- **RAM total**: ~2-3 GB (6 containers)

## 🔗 Referências

- Docker Compose: [docker-compose.yml](../docker-compose.yml)
- Configurações: [docker/](../docker/)
- Scripts de teste: [scripts/](../scripts/)
