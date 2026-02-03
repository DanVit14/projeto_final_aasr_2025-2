# Requisitos e Dependências do Projeto

## Sistema Operacional
- **Debian 12** (Bookworm)
- VM limpa (sem instalações prévias)

## Dependências do Sistema

### Essenciais
- **Docker** (versão 24.0 ou superior)
- **Docker Compose** (versão 2.20 ou superior)
- **Git** (para versionamento)
- **curl** e **wget** (para downloads)

### Ferramentas de Rede
- **net-tools** (ifconfig, netstat)
- **iputils-ping** (ping)
- **dnsutils** (dig, nslookup)
- **tcpdump** (análise de rede)
- **iptables** e **netfilter-persistent** (firewall)

### Utilitários
- **vim** ou **nano** (editores de texto)
- **htop** (monitoramento)
- **tree** (visualização de diretórios)
- **jq** (processamento JSON)
- **zip/unzip** (compactação)

## Serviços que serão executados em Containers

### Container 1: LDAP/AD (Samba)
- **Samba 4** (Active Directory Domain Controller)
- **Kerberos**
- **DNS** (opcional, via Samba)

### Container 2: Firewall
- **iptables/netfilter**
- **rsyslog** (para logs do firewall)

### Container 3: SMTP
- **Postfix** (servidor SMTP)
- **Dovecot** (IMAP/POP3 para acesso a caixas)
- **Nota:** ClamAV/Amavis/SpamAssassin não implementados (ver `docs/servicos/SMTP.md` para justificativa)

### Container 4: Banco de Dados
- **PostgreSQL 15** (banco de dados)

### Container 5: Logs + NTP
- **rsyslog** (servidor de logs centralizado)
- **chrony** (servidor NTP)

## Recursos do Sistema Recomendados

### VM VirtualBox
- **RAM:** Mínimo 4GB (recomendado 8GB)
- **Disco:** Mínimo 20GB (recomendado 40GB)
- **CPU:** 2 cores (recomendado 4 cores)

### Espaço em Disco por Container
- LDAP/AD: ~2GB
- Firewall: ~500MB
- SMTP: ~1GB
- Database: ~1GB (sem dados)
- Logs+NTP: ~500MB

**Total estimado:** ~5GB + espaço para dados e logs

## Portas que serão utilizadas

| Serviço | Porta(s) | Protocolo |
|---------|----------|-----------|
| LDAP | 389, 636 | TCP |
| Kerberos | 88 | TCP/UDP |
| SMB/CIFS | 445 | TCP |
| DNS | 53 | TCP/UDP |
| SMTP | 25, 587 | TCP |
| IMAP | 993 | TCP |
| POP3 | 995 | TCP |
| PostgreSQL | 5432 | TCP |
| rsyslog | 514 | TCP/UDP |
| NTP | 123 | UDP |
| SSH | 22 | TCP |

## Configurações de Rede

### Rede Docker
- **Rede:** 10.0.1.0/24 (bridge customizada)
- **Gateway:** 10.0.1.1
- **DNS:** Configurado via docker-compose

### Endereços IP dos Containers
- LDAP/AD: 10.0.1.10
- Firewall: 10.0.1.20
- SMTP+AV: 10.0.1.30
- Database: 10.0.1.40
- Logs+NTP: 10.0.1.50
- Cliente (opcional): 10.0.1.60

## Instalação Rápida

Execute o script de setup na VM:

```bash
chmod +x setup_vm.sh
./setup_vm.sh
```

Ou instale manualmente seguindo as instruções no script.

## Verificação Pós-Instalação

```bash
# Verificar Docker
docker --version
docker ps

# Verificar Docker Compose
docker-compose --version

# Verificar Git
git --version

# Verificar permissões Docker
groups | grep docker
```

## Notas Importantes

1. **Permissões Docker:** Após instalar Docker, faça logout/login ou execute `newgrp docker` para usar Docker sem sudo.

2. **Firewall do Host:** Algumas portas podem precisar ser liberadas no firewall do host (se houver).

3. **Recursos:** Se a VM tiver pouca RAM, considere reduzir o número de containers simultâneos ou aumentar a memória da VM.

4. **Backup:** Configure backups regulares dos volumes Docker (especialmente do banco de dados).

5. **Logs:** Monitore o espaço em disco, especialmente os logs do rsyslog centralizado.
