# Projeto Final - AASR 2025

Infraestrutura Corporativa Integrada com Docker Compose

---

## 📋 Visão Geral

Sistema completo de infraestrutura corporativa simulada com 6 serviços integrados:

1. **Firewall** - Proteção de rede e port forwarding
2. **LDAP** (Samba AD DC) - Autenticação centralizada
3. **SMTP** (Postfix + Dovecot) - Servidor de email
4. **Database** (PostgreSQL) - Banco de dados e auditoria
5. **Logs-NTP** (Rsyslog + Chrony) - Logs centralizados e sincronização de tempo
6. **Cliente** - Testes e simulação de usuário

---

## 🚀 Início Rápido

### 1. Clonar e Iniciar

```bash
git clone <url-do-repositorio>
cd projeto_final_aasr_2025-2

# Build e iniciar
docker-compose build
docker-compose up -d

# Aguardar 30s para inicialização
sleep 30
```

### 2. Validar Instalação

```bash
# Teste básico
./scripts/test_services.sh

# Teste completo (End-to-End)
./scripts/test_end_to_end.sh
```

### 3. Ver Resultados

```bash
cat docs/teste_end_to_end.txt
```

**Esperado:** 6/6 serviços integrados ✓

---

## 📚 Documentação

### Documentos Principais

| Documento | Descrição |
|-----------|-----------|
| **[01_INSTALACAO.md](docs/01_INSTALACAO.md)** | Como instalar e executar o projeto |
| **[02_TOPOLOGIA.md](docs/02_TOPOLOGIA.md)** | Arquitetura da rede e design do sistema |
| **[03_TESTE_E2E.md](docs/03_TESTE_E2E.md)** | Teste de integração completo |

### Documentação por Serviço

| Serviço | Documento |
|---------|-----------|
| Firewall | **[servicos/FIREWALL.md](docs/servicos/FIREWALL.md)** |
| LDAP | **[servicos/LDAP.md](docs/servicos/LDAP.md)** |
| SMTP | **[servicos/SMTP.md](docs/servicos/SMTP.md)** |
| Database | **[servicos/DATABASE.md](docs/servicos/DATABASE.md)** |
| Logs-NTP | **[servicos/LOGS_NTP.md](docs/servicos/LOGS_NTP.md)** |
| Cliente | **[servicos/CLIENTE.md](docs/servicos/CLIENTE.md)** |

### Evidências

- **[EVIDENCIAS/README.md](docs/EVIDENCIAS/README.md)** - Guia para coleta de evidências

---

## 🌐 Topologia

```
┌──────────────┐
│   CLIENTE    │ 10.0.1.60
└──────┬───────┘
       │
       ├─────────┬──────────────────┐
       │         │                  │
       ▼         ▼                  ▼
  ┌─────────┐ ┌─────────┐   ┌────────────┐
  │  LDAP   │ │  SMTP   │   │  FIREWALL  │ 10.0.1.20
  │10.0.1.30│ │10.0.1.30│   └─────┬──────┘
  └─────────┘ └────┬────┘         │ (Port Forward)
                   │              │ 5432 → Database
                   ▼              ▼
             ┌────────────┐  ┌──────────────┐
             │  LOGS-NTP  │  │   DATABASE   │ 10.0.1.40
             │ (Rsyslog)  │  │ (PostgreSQL) │
             └────────────┘  └──────────────┘
              10.0.1.50
```

**Rede:** 10.0.1.0/24 (aasr_net)

Ver detalhes em [docs/02_TOPOLOGIA.md](docs/02_TOPOLOGIA.md)

---

## 📊 Endereçamento

| Serviço | IP | Porta(s) Host | Porta(s) Container |
|---------|---------|---------------|-------------------|
| Firewall | 10.0.1.20 | 2222, 5433 | 22, 5432 |
| LDAP | 10.0.1.30 | - | 389, 636 |
| SMTP | 10.0.1.30 | 2525 | 25 |
| Database | 10.0.1.40 | 5432 | 5432 |
| Logs-NTP | 10.0.1.50 | 123/udp | 123/udp, 514/udp |
| Cliente | 10.0.1.60 | - | - |

---

## 🧪 Scripts de Teste

### Testes Principais

```bash
# Teste End-to-End (completo)
./scripts/test_end_to_end.sh

# Testes básicos de serviços
./scripts/test_services.sh

# Firewall (regras e port forward)
./scripts/test_firewall_apenas_regras.sh

# Ver regras iptables
./scripts/show_firewall_rules.sh
```

### Diagnóstico

```bash
# Debug firewall
./scripts/debug_firewall.sh

# Diagnóstico rsyslog
./scripts/diagnose_rsyslog.sh

# Corrigir rsyslog
./scripts/fix_rsyslog.sh
```

Ver lista completa em [scripts/README_TESTES.md](scripts/README_TESTES.md)

---

## ✅ Funcionalidades Implementadas

### Integração Completa

- ✅ **LDAP ↔ SMTP:** Validação de usuários para email
- ✅ **SMTP → Logs-NTP:** Logs centralizados via rsyslog
- ✅ **Cliente → Firewall → Database:** Port forwarding (DNAT)
- ✅ **Containers → Logs-NTP:** Sincronização NTP
- ✅ **Sistema → Database:** Auditoria de transações

### Segurança

- ✅ Firewall com iptables
- ✅ Autenticação centralizada (LDAP)
- ✅ Antispam (SpamAssassin)
- ✅ ACLs (Access Control Lists)
- ✅ Relay restrictions no SMTP

### Auditoria e Monitoramento

- ✅ Logs centralizados (rsyslog)
- ✅ Auditoria no banco de dados
- ✅ Rastreabilidade end-to-end (test_id)
- ✅ Logging de conexões no firewall

---

## 🛠️ Comandos Úteis

### Gerenciar Containers

```bash
# Ver status
docker-compose ps

# Logs
docker-compose logs [serviço]
docker-compose logs -f smtp  # Follow

# Parar/Iniciar
docker-compose stop
docker-compose start

# Reiniciar
docker-compose restart [serviço]

# Rebuild
docker-compose build [serviço]
docker-compose up -d [serviço]
```

### Acessar Containers

```bash
# Bash interativo
docker-compose exec [serviço] bash

# Exemplos
docker-compose exec smtp bash
docker-compose exec database bash
docker-compose exec cliente bash
```

### Limpeza

```bash
# Parar e remover
docker-compose down

# Remover volumes (apaga dados!)
docker-compose down -v

# Rebuild completo
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

---

## 📁 Estrutura do Projeto

```
.
├── docker/                  # Dockerfiles e configs
│   ├── firewall/
│   ├── ldap/
│   ├── smtp/
│   ├── database/
│   ├── logs-ntp/
│   └── cliente/
├── scripts/                 # Scripts de teste
│   ├── test_end_to_end.sh
│   ├── test_services.sh
│   ├── test_firewall_*.sh
│   └── ...
├── docs/                    # Documentação
│   ├── 01_INSTALACAO.md
│   ├── 02_TOPOLOGIA.md
│   ├── 03_TESTE_E2E.md
│   ├── servicos/           # Doc de cada serviço
│   └── EVIDENCIAS/
├── backups/                 # Backups do database
├── docker-compose.yml       # Orquestração
└── README.md               # Este arquivo
```

---

## 🎓 Para Apresentação

### Demonstração Sugerida (5-10 min)

1. **Mostrar topologia** (diagrama visual)
2. **Executar teste E2E** (`./scripts/test_end_to_end.sh`)
3. **Destacar score** (6/6 serviços integrados)
4. **Mostrar firewall** (regras iptables com port forward)
5. **Mostrar logs centralizados** (estrutura em `/var/log/remote/`)
6. **Mostrar auditoria** (tabela `audit_log` no PostgreSQL)

### Comandos para Demonstração Ao Vivo

```bash
# Firewall: Regras e port forward
docker-compose exec firewall iptables -t nat -L PREROUTING -n -v

# Logs: Estrutura centralizada
docker-compose exec logs-ntp ls -lR /var/log/remote/

# Database: Auditoria
docker-compose exec database psql -U app_user -d empresa_db \
  -c "SELECT * FROM audit_log ORDER BY timestamp DESC LIMIT 5;"

# LDAP: Usuários
docker-compose exec ldap samba-tool user list
```

---

## 📞 Suporte

### Troubleshooting

Ver seção de troubleshooting em cada documento de serviço:
- [FIREWALL.md](docs/servicos/FIREWALL.md#troubleshooting)
- [SMTP.md](docs/servicos/SMTP.md#troubleshooting)
- [DATABASE.md](docs/servicos/DATABASE.md#troubleshooting)

### Logs

```bash
# Ver logs de um serviço
docker-compose logs [serviço]

# Últimas 50 linhas
docker-compose logs --tail=50 [serviço]

# Tempo real
docker-compose logs -f [serviço]
```

---

## 🔗 Links Úteis

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Samba AD DC](https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller)
- [Postfix Documentation](http://www.postfix.org/documentation.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

**Projeto: Sistema de infraestrutura corporativa integrada com 6 serviços demonstrando integração completa e workflow end-to-end realista.** ✅
