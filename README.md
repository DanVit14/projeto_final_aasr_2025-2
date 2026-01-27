# Projeto Final AASR 2025-2

Infraestrutura corporativa completa distribuída em containers Docker.

## 📋 Requisitos

- **VM:** Debian 12 (limpa, sem instalações)
- **RAM:** Mínimo 4GB (recomendado 8GB)
- **Disco:** Mínimo 20GB (recomendado 40GB)

## 🚀 Setup Inicial na VM

### 1. Clonar o repositório
```bash
git clone https://github.com/DanVit14/projeto_final_aasr_2025-2.git
cd projeto_final_aasr_2025-2
```

### 2. Executar script de setup
```bash
chmod +x setup_vm.sh
./setup_vm.sh
```

### 3. Fazer logout/login (para permissões Docker)
```bash
# Ou executar:
newgrp docker
```

### 4. Verificar instalação
```bash
docker --version
docker-compose --version
```

## 🏗️ Estrutura do Projeto

```
projeto_final_aasr_2025-2/
├── docker-compose.yml          # Orquestração de containers
├── setup_vm.sh                 # Script de instalação
├── REQUIREMENTS.md             # Lista de dependências
├── docker/
│   ├── ldap/                   # Container LDAP/AD (Samba)
│   ├── firewall/               # Container Firewall
│   ├── smtp/                   # Container SMTP + Antivírus
│   ├── database/               # Container PostgreSQL
│   ├── logs-ntp/               # Container Logs + NTP
│   └── cliente/                # Container Cliente de Teste
├── scripts/
│   ├── backup_db.sh            # Backup do banco
│   ├── restore_db.sh           # Restauração do banco
│   └── test_services.sh        # Testes dos serviços
├── configs/                    # Configurações gerais
├── backups/                    # Backups do banco
└── docs/                       # Documentação técnica
```

## 🐳 Containers e Serviços

| Container | IP | Serviços |
|-----------|----|----------| 
| ldap | 10.0.1.10 | Samba AD, LDAP, Kerberos, SMB |
| firewall | 10.0.1.20 | iptables/netfilter |
| smtp | 10.0.1.30 | Postfix, ClamAV, SpamAssassin |
| database | 10.0.1.40 | PostgreSQL 15 |
| logs-ntp | 10.0.1.50 | rsyslog, chrony |
| cliente | 10.0.1.60 | Cliente de teste |

## 🚦 Comandos Úteis

### Iniciar todos os containers
```bash
docker-compose up -d
```

### Ver logs de um serviço
```bash
docker-compose logs -f [servico]
# Exemplo: docker-compose logs -f ldap
```

### Parar todos os containers
```bash
docker-compose down
```

### Rebuild de um container
```bash
docker-compose build [servico]
docker-compose up -d [servico]
```

### Entrar em um container
```bash
docker-compose exec [servico] bash
# Exemplo: docker-compose exec database bash
```

### Backup do banco de dados
```bash
./scripts/backup_db.sh
```

### Restaurar banco de dados
```bash
./scripts/restore_db.sh backups/backup_YYYYMMDD.sql
```

## 📝 Documentação

- **PLANO_PROJETO.md** - Plano completo de implementação
- **REQUIREMENTS.md** - Lista de dependências e requisitos
- **docs/TOPOLOGIA.md** - Diagrama de topologia de rede
- **docs/OPCAO_SEM_SCAN_ANTIVIRUS.md** - Nota sobre antivírus desativado
- **docs/** - Documentação técnica detalhada

## 🔧 Desenvolvimento

1. Trabalhar nos arquivos na VM
2. Commitar mudanças:
   ```bash
   git add .
   git commit -m "Descrição das mudanças"
   git push
   ```
3. No host (WSL), fazer pull:
   ```bash
   git pull
   ```

## 📅 Data de Apresentação

**27/01/2026**

## 📚 Tópicos Implementados

- ✅ Permissões avançadas e ACLs
- ✅ Firewall com Netfilter
- ✅ NTP (sincronização de tempo)
- ✅ Serviços de log e log centralizado
- ✅ LDAP e integração com serviços
- ✅ Samba/AD e compartilhamentos
- ✅ Antivírus corporativo
- ✅ Servidor SMTP (contas, aliases, domínio virtual, antispam, quotas, Maildir)
- ✅ Banco de dados com CRUD, backup e restauração

## ⚠️ Notas Importantes

- **Antivírus:** O scan de vírus (ClamAV) está temporariamente desativado (content_filter comentado no Postfix). Entrega de correio e antispam estão operacionais. Ver **docs/OPCAO_SEM_SCAN_ANTIVIRUS.md**.
- Não configurar replicação master-slave no banco de dados
- Todos os arquivos devem estar versionados no Git
- Documentar todas as decisões e problemas encontrados
- Coletar evidências (prints, logs, configurações)
