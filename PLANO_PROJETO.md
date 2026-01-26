# Plano de Implementação - Infraestrutura Corporativa Distribuída

## Visão Geral
Projeto individual de infraestrutura corporativa distribuída em containers Docker, executados em uma VM VirtualBox com Debian 12.

**Data de Apresentação:** 27/01/2026

---

## Topologia Proposta (5+ Serviços)

### Arquitetura de Rede
```
┌─────────────────────────────────────────────────────────┐
│              VM Debian 12 (Host)                        │
│  IP: 192.168.56.100/24 (Rede Interna)                  │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Container 1 │  │  Container 2 │  │  Container 3 │ │
│  │   LDAP/AD    │  │   Firewall   │  │  SMTP + AV   │ │
│  │  10.0.1.10   │  │  10.0.1.20   │  │  10.0.1.30   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │  Container 4 │  │  Container 5 │                    │
│  │   Database   │  │ Logs + NTP   │                    │
│  │  10.0.1.40   │  │  10.0.1.50   │                    │
│  └──────────────┘  └──────────────┘                    │
│                                                         │
│  ┌──────────────┐                                      │
│  │  Container 6 │  (Opcional - Cliente de Teste)       │
│  │   Cliente    │                                      │
│  │  10.0.1.60   │                                      │
│  └──────────────┘                                      │
└─────────────────────────────────────────────────────────┘
```

### Endereçamento IP

| Container | Serviço | IP | Portas Principais |
|-----------|---------|----|-------------------|
| Container 1 | LDAP/AD (Samba AD) | 10.0.1.10 | 389, 636, 88, 445 |
| Container 2 | Firewall (iptables/netfilter) | 10.0.1.20 | 22, 80, 443 |
| Container 3 | SMTP (Postfix) + Antivírus (ClamAV) | 10.0.1.30 | 25, 587, 993, 995 |
| Container 4 | Database (PostgreSQL) | 10.0.1.40 | 5432 |
| Container 5 | Logs (rsyslog/ELK) + NTP (chrony) | 10.0.1.50 | 514, 123 |
| Container 6 | Cliente de Teste (Opcional) | 10.0.1.60 | - |

**Rede Docker:** `10.0.1.0/24` (bridge network customizada)

---

## Distribuição de Serviços por Container

### Container 1: LDAP/Active Directory (Samba AD)
**Imagem Base:** Debian 12 slim
**Funções:**
- Samba 4 como Active Directory Domain Controller
- LDAP (porta 389/636)
- Kerberos (porta 88)
- DNS interno (opcional)
- Compartilhamentos SMB/CIFS

**Configurações:**
- Domínio: `empresa.local`
- Usuários de teste: admin, user1, user2
- Compartilhamentos: /shared/public, /shared/private
- Integração com SMTP para autenticação de e-mails

**Permissões e ACLs:**
- Configurar ACLs nos compartilhamentos
- Permissões diferenciadas por grupos (admins, users, guests)

---

### Container 2: Firewall (Netfilter/iptables)
**Imagem Base:** Debian 12 com iptables
**Funções:**
- Firewall centralizado usando iptables/netfilter
- Regras de NAT (se necessário)
- Logging de tráfego bloqueado
- Políticas de segurança por serviço

**Regras Principais:**
- Permitir tráfego entre containers internos
- Bloquear tráfego não autorizado
- Permitir apenas portas específicas por serviço
- Logging de tentativas de acesso bloqueadas

**Testes:**
- Bloquear acesso a porta específica
- Verificar logs de bloqueio
- Testar comunicação entre containers

---

### Container 3: SMTP + Antivírus
**Imagem Base:** Debian 12
**Funções:**
- Postfix como servidor SMTP
- ClamAV como antivírus corporativo
- Amavis para integração Postfix + ClamAV
- Autenticação LDAP/AD
- Domínio virtual: `@empresa.local`
- Quotas de e-mail (Maildir)
- Antispam (SpamAssassin)

**Configurações:**
- Domínio: `empresa.local`
- Contas de e-mail: admin@empresa.local, user1@empresa.local
- Aliases: suporte@empresa.local -> admin@empresa.local
- Quotas: 100MB por usuário
- Maildir: /var/mail/vhosts/empresa.local/
- Antispam: SpamAssassin integrado
- Antivírus: ClamAV scanando todos os e-mails

**Testes:**
- Envio de e-mail entre contas
- Teste de antivírus (EICAR test file)
- Teste de antispam
- Verificação de quotas

---

### Container 4: Banco de Dados
**Imagem Base:** PostgreSQL 15 (oficial)
**Funções:**
- PostgreSQL como banco de dados
- CRUD completo
- Backup automático (pg_dump)
- Restauração de backups
- **NÃO** configurar replicação master-slave

**Configurações:**
- Database: `empresa_db`
- Usuário: `app_user`
- Tabelas de exemplo: usuarios, produtos, vendas
- Backup diário via cron
- Scripts de backup e restauração

**Testes:**
- Operações CRUD (Create, Read, Update, Delete)
- Backup manual e automático
- Restauração de backup
- Verificação de integridade

---

### Container 5: Logs Centralizados + NTP
**Imagem Base:** Debian 12
**Funções:**
- rsyslog como servidor de logs centralizado
- chrony como servidor NTP
- Receber logs de todos os containers
- Sincronização de tempo para toda a infraestrutura

**Configurações:**
- rsyslog: receber logs via UDP/TCP 514
- chrony: servidor NTP local
- Timezone: America/Sao_Paulo
- Logs organizados por container/serviço

**Testes:**
- Envio de logs de outros containers
- Verificação de sincronização NTP
- Teste de falha do NTP primário (fallback)

---

### Container 6: Cliente de Teste (Opcional)
**Imagem Base:** Debian 12
**Funções:**
- Cliente para testar serviços
- Autenticação LDAP
- Acesso a compartilhamentos Samba
- Envio de e-mails
- Conexão ao banco de dados
- Verificação de sincronização NTP

---

## Estrutura do Projeto Git

```
projeto_final_aasr_2025-2/
├── README.md
├── PLANO_PROJETO.md
├── docker-compose.yml              # Orquestração de todos os containers
├── docker/
│   ├── ldap/
│   │   ├── Dockerfile
│   │   ├── samba.conf
│   │   └── init.sh
│   ├── firewall/
│   │   ├── Dockerfile
│   │   ├── iptables.rules
│   │   └── firewall.sh
│   ├── smtp/
│   │   ├── Dockerfile
│   │   ├── main.cf (Postfix)
│   │   ├── master.cf
│   │   └── clamav.conf
│   ├── database/
│   │   ├── Dockerfile
│   │   ├── init.sql
│   │   └── backup.sh
│   ├── logs-ntp/
│   │   ├── Dockerfile
│   │   ├── rsyslog.conf
│   │   └── chrony.conf
│   └── cliente/
│       ├── Dockerfile
│       └── test_scripts/
├── scripts/
│   ├── setup.sh                    # Script de inicialização
│   ├── backup_db.sh                # Backup do banco
│   ├── restore_db.sh               # Restauração do banco
│   └── test_services.sh            # Scripts de teste
├── configs/
│   ├── network.conf
│   └── domain.conf
├── backups/
│   └── .gitkeep
├── docs/
│   ├── topologia.md                # Documentação da topologia
│   ├── configuracao.md             # Decisões de configuração
│   ├── problemas.md                # Problemas encontrados
│   └── evidencias.md               # Prints e logs
└── .gitignore
```

---

## Fases de Implementação

### Fase 1: Preparação do Ambiente (Dia 1)
- [ ] Instalar Docker e Docker Compose no Debian 12
- [ ] Criar rede Docker customizada (10.0.1.0/24)
- [ ] Configurar estrutura de diretórios do projeto
- [ ] Inicializar repositório Git
- [ ] Criar docker-compose.yml base

### Fase 2: Container 5 - Logs + NTP (Dia 2)
- [ ] Criar Dockerfile para logs-ntp
- [ ] Configurar rsyslog como servidor centralizado
- [ ] Configurar chrony como servidor NTP
- [ ] Testar recebimento de logs
- [ ] Testar sincronização NTP
- [ ] Documentar configurações

### Fase 3: Container 1 - LDAP/AD (Dia 3-4)
- [ ] Criar Dockerfile para Samba AD
- [ ] Configurar domínio empresa.local
- [ ] Criar usuários e grupos
- [ ] Configurar compartilhamentos SMB
- [ ] Implementar ACLs nos compartilhamentos
- [ ] Testar autenticação LDAP
- [ ] Documentar configurações

### Fase 4: Container 4 - Banco de Dados (Dia 5)
- [ ] Criar Dockerfile para PostgreSQL
- [ ] Configurar banco de dados
- [ ] Criar tabelas de exemplo
- [ ] Implementar scripts de backup
- [ ] Implementar scripts de restauração
- [ ] Testar operações CRUD
- [ ] Testar backup e restauração
- [ ] Documentar configurações

### Fase 5: Container 3 - SMTP + Antivírus (Dia 6-7)
- [ ] Criar Dockerfile para SMTP
- [ ] Configurar Postfix
- [ ] Integrar com LDAP/AD para autenticação
- [ ] Configurar domínio virtual
- [ ] Criar contas de e-mail
- [ ] Configurar aliases
- [ ] Implementar quotas (Maildir)
- [ ] Instalar e configurar ClamAV
- [ ] Instalar e configurar SpamAssassin
- [ ] Integrar Amavis (Postfix + ClamAV + SpamAssassin)
- [ ] Testar envio/recebimento de e-mails
- [ ] Testar antivírus (EICAR)
- [ ] Testar antispam
- [ ] Documentar configurações

### Fase 6: Container 2 - Firewall (Dia 8)
- [ ] Criar Dockerfile para firewall
- [ ] Configurar iptables/netfilter
- [ ] Criar regras de firewall
- [ ] Implementar logging de bloqueios
- [ ] Testar bloqueio de tráfego
- [ ] Testar comunicação permitida
- [ ] Documentar configurações

### Fase 7: Integração e Testes (Dia 9-10)
- [ ] Integrar todos os serviços
- [ ] Testar autenticação LDAP em todos os serviços
- [ ] Testar comunicação entre containers
- [ ] Testar firewall bloqueando/permitindo tráfego
- [ ] Testar logs centralizados
- [ ] Testar sincronização NTP
- [ ] Testar backup e restauração do banco
- [ ] Testar envio de e-mails com antivírus
- [ ] Testar falhas (ex: NTP primário)

### Fase 8: Documentação Final (Dia 11)
- [ ] Completar documentação técnica
- [ ] Adicionar prints de evidências
- [ ] Adicionar trechos de configuração
- [ ] Adicionar logs de funcionamento
- [ ] Criar diagrama de topologia
- [ ] Documentar problemas encontrados e soluções
- [ ] Preparar apresentação

### Fase 9: Ensaios e Ajustes (Dia 12-13)
- [ ] Revisar toda a documentação
- [ ] Testar todos os serviços novamente
- [ ] Ensaiar apresentação
- [ ] Preparar para modificações ao vivo
- [ ] Verificar que tudo está versionado no Git

---

## Decisões de Configuração e Justificativas

### Rede Docker Customizada
**Decisão:** Usar rede bridge customizada (10.0.1.0/24)
**Justificativa:** 
- Isolamento da rede host
- Controle total sobre endereçamento
- Facilita configuração de firewall
- Permite comunicação entre containers

### Samba AD ao invés de OpenLDAP
**Decisão:** Usar Samba 4 como AD
**Justificativa:**
- Suporta Active Directory completo
- Integração nativa com SMB/CIFS
- Melhor compatibilidade com Windows
- Suporta Kerberos nativamente

### PostgreSQL ao invés de MySQL
**Decisão:** Usar PostgreSQL
**Justificativa:**
- Mais robusto para ambientes corporativos
- Melhor suporte a ACLs e permissões
- Ferramentas de backup mais completas
- Padrão em muitos ambientes corporativos

### rsyslog + chrony no mesmo container
**Decisão:** Agrupar logs e NTP
**Justificativa:**
- Ambos são serviços leves
- Reduz número de containers
- Facilita gerenciamento
- Economiza recursos

### Maildir ao invés de mbox
**Decisão:** Usar Maildir
**Justificativa:**
- Melhor para quotas
- Mais seguro (sem lock de arquivo)
- Padrão moderno
- Melhor performance

---

## Testes de Funcionamento

### 1. LDAP/AD
- [ ] Autenticação de usuário via LDAP
- [ ] Listagem de usuários e grupos
- [ ] Acesso a compartilhamentos SMB
- [ ] Verificação de ACLs
- [ ] Integração com SMTP

### 2. Firewall
- [ ] Bloqueio de porta não autorizada
- [ ] Permissão de comunicação entre containers
- [ ] Logging de tentativas bloqueadas
- [ ] Teste de regras NAT (se aplicável)

### 3. SMTP + Antivírus
- [ ] Envio de e-mail entre contas
- [ ] Recebimento de e-mail
- [ ] Verificação de aliases
- [ ] Teste de antivírus (EICAR)
- [ ] Teste de antispam
- [ ] Verificação de quotas
- [ ] Autenticação LDAP

### 4. Banco de Dados
- [ ] CREATE (inserção de dados)
- [ ] READ (consultas)
- [ ] UPDATE (atualizações)
- [ ] DELETE (remoções)
- [ ] Backup completo
- [ ] Restauração de backup
- [ ] Verificação de integridade

### 5. Logs + NTP
- [ ] Recebimento de logs de todos os containers
- [ ] Organização de logs por serviço
- [ ] Sincronização NTP em todos os containers
- [ ] Teste de falha do NTP primário
- [ ] Verificação de drift de tempo

### 6. Integração Geral
- [ ] Comunicação entre todos os serviços
- [ ] Autenticação unificada (LDAP)
- [ ] Logs centralizados funcionando
- [ ] Tempo sincronizado em toda infraestrutura

---

## Problemas Esperados e Soluções

### Problema 1: Permissões no Docker
**Solução:** Usar volumes com permissões corretas, --privileged se necessário para alguns serviços

### Problema 2: Resolução de nomes entre containers
**Solução:** Usar docker-compose com service names, configurar /etc/hosts se necessário

### Problema 3: Sincronização de tempo em containers
**Solução:** Usar --cap-add SYS_TIME, compartilhar /etc/localtime, configurar chrony

### Problema 4: Firewall em container
**Solução:** Usar --cap-add NET_ADMIN, --cap-add NET_RAW, ou --network host para algumas regras

### Problema 5: Integração LDAP com Postfix
**Solução:** Usar postfix-ldap, configurar corretamente os atributos LDAP

---

## Evidências Necessárias

### Screenshots/Prints
1. Topologia de rede (diagrama)
2. Configuração de cada serviço (trechos principais)
3. Testes de funcionamento:
   - Autenticação LDAP
   - Envio/recebimento de e-mail
   - Operações CRUD no banco
   - Logs centralizados
   - Sincronização NTP
   - Regras de firewall
4. Backup e restauração do banco
5. Teste de antivírus (scan do EICAR)
6. Teste de antispam
7. Verificação de quotas de e-mail
8. ACLs funcionando

### Logs
1. Logs de autenticação LDAP
2. Logs de firewall (tentativas bloqueadas)
3. Logs de SMTP (envio/recebimento)
4. Logs de antivírus (scans)
5. Logs de banco de dados
6. Logs centralizados (rsyslog)
7. Logs de sincronização NTP

### Configurações
1. Trechos principais de cada arquivo de configuração
2. Regras de iptables
3. Configuração de domínio AD
4. Configuração de Postfix
5. Configuração de PostgreSQL
6. Configuração de rsyslog
7. Configuração de chrony

---

## Checklist Final Antes da Apresentação

- [ ] Todos os containers estão funcionando
- [ ] Todos os serviços estão integrados
- [ ] Documentação completa e atualizada
- [ ] Todos os arquivos versionados no Git
- [ ] Scripts de teste funcionando
- [ ] Backups funcionando
- [ ] Evidências coletadas (prints, logs)
- [ ] Apresentação preparada
- [ ] Conhecimento de todas as configurações
- [ ] Preparado para modificações ao vivo

---

## Comandos Úteis

```bash
# Iniciar todos os containers
docker-compose up -d

# Ver logs de um container
docker-compose logs -f [servico]

# Entrar em um container
docker-compose exec [servico] bash

# Parar todos os containers
docker-compose down

# Rebuild de um container
docker-compose build [servico]
docker-compose up -d [servico]

# Verificar rede
docker network inspect projeto_final_aasr_default

# Backup do banco
./scripts/backup_db.sh

# Restaurar banco
./scripts/restore_db.sh backup_file.sql
```

---

## Próximos Passos

1. **Revisar este plano** e ajustar conforme necessário
2. **Criar estrutura de diretórios** do projeto
3. **Inicializar repositório Git** e fazer primeiro commit
4. **Começar pela Fase 1** (preparação do ambiente)
5. **Seguir as fases sequencialmente**, documentando cada etapa
6. **Testar constantemente** cada serviço após implementação
7. **Documentar problemas** e soluções encontradas
8. **Coletar evidências** durante todo o processo

---

**Boa sorte com o projeto! 🚀**
