# Decisões Técnicas e Problemas Encontrados

## 🎯 Decisões de Arquitetura

### 1. Docker Compose vs Máquinas Virtuais

**Decisão**: Usar Docker Compose com containers isolados

**Justificativa**:
- ✅ Portabilidade entre ambientes
- ✅ Isolamento de serviços
- ✅ Facilidade de rebuild/reset
- ✅ Consumo de recursos otimizado
- ✅ Versionamento completo (Dockerfiles + compose)

**Alternativa considerada**: VMs separadas (VMware/VirtualBox)
- ❌ Maior consumo de RAM (1-2 GB por VM)
- ❌ Complexidade de networking
- ❌ Dificuldade de versionamento

### 2. Rede Isolada (Bridge Customizada)

**Decisão**: Criar rede `aasr_net` (10.0.1.0/24) com IPs fixos

**Justificativa**:
- ✅ Endereçamento previsível para testes
- ✅ Isolamento da rede do host
- ✅ Simula rede corporativa real
- ✅ Facilita configuração de firewall

**Configuração**:
```yaml
networks:
  aasr_net:
    driver: bridge
    ipam:
      config:
        - subnet: 10.0.1.0/24
```

### 3. LDAP via Samba AD (não OpenLDAP)

**Decisão**: Usar Samba AD para autenticação centralizada

**Justificativa**:
- ✅ Integração nativa com SMB/CIFS
- ✅ Kerberos incluso
- ✅ Compatibilidade com Windows
- ✅ Mais próximo de ambiente corporativo real

**Desafio**: Configuração mais complexa que OpenLDAP standalone
- Resolvido com script `provision.sh` automatizado

### 4. Postfix sem chroot

**Decisão**: Desativar chroot no `master.cf` (coluna 5 = `n`)

**Justificativa**:
- ❌ Erros "bad command startup" com chroot ativo
- ✅ Simplifica acesso a sockets (LDAP, Amavis)
- ✅ Containers já fornecem isolamento
- ⚠️ Trade-off: Segurança vs Funcionalidade

**Alternativa**: Configurar chroot corretamente
- Requer copiar libs, configs, sockets para jail
- Complexidade não justificada em ambiente containerizado

### 5. Porta SMTP Externa (2525 no host)

**Decisão**: Mapear `2525:25` (host:container) para SMTP

**Justificativa**:
- ✅ Evita conflito com porta 22 (SSH do firewall)
- ✅ Permite SSH no firewall (2222) e SMTP (2525)
- ✅ Mantém porta 25 interna para testes realistas

**Problema original**: Port binding conflict
```
ERROR: for firewall Cannot start service firewall: 
  Ports are not available: listen tcp 0.0.0.0:22: bind: address already in use
```

### 6. Cliente Persistente (não temporário)

**Decisão**: Container `cliente` com `command: sleep infinity`

**Justificativa**:
- ❌ `docker-compose run --rm` criava rede temporária
- ❌ Falhas de conectividade intermitentes
- ✅ Container persistente mantém estado de rede
- ✅ Facilita debugging interativo

**Configuração**:
```yaml
cliente:
  command: sleep infinity
  restart: unless-stopped
```

### 7. Desativação do ClamAV

**Decisão**: Comentar `content_filter` no Postfix

**Justificativa**: Ver [OPCAO_SEM_ANTIVIRUS.md](./OPCAO_SEM_ANTIVIRUS.md)
- Startup 85% mais rápido (20s vs 135s)
- Mantém antispam (SpamAssassin)
- Múltiplas camadas de segurança ativas

### 8. Backup Manual vs Automatizado

**Decisão**: Scripts manuais (`backup_db.sh`, `restore_db.sh`)

**Justificativa**:
- ✅ Simplicidade para demonstração
- ✅ Controle explícito do processo
- ✅ Facilita troubleshooting

**Melhoria futura**: Cron job para backups diários
```bash
0 2 * * * /path/to/backup_db.sh
```

## 🐛 Problemas Encontrados e Soluções

### Problema 1: test_services.sh Not Found

**Erro**:
```
bash: test_services.sh: command not found
```

**Causa**: Script copiado durante `docker build`, mas contexto perdido

**Solução**: Montar via volume no `docker-compose.yml`
```yaml
volumes:
  - ./scripts/test_services.sh:/usr/local/bin/test_services.sh:ro
```

### Problema 2: Port Conflict (SSH Firewall)

**Erro**:
```
Ports are not available: listen tcp 0.0.0.0:22: bind: address already in use
```

**Causa**: VM já usa porta 22 para SSH

**Solução**: Mapear para porta alternativa
```yaml
ports:
  - "2222:22"  # SSH firewall
```

### Problema 3: SMTP Test Hanging

**Erro**: Netcat (`nc`) bloqueava esperando resposta "220"

**Causa raiz**: Postfix demorava 135s para inicializar (ClamAV)

**Soluções aplicadas**:
1. Reordenar `init.sh`: Postfix **antes** de ClamAV/Amavis
2. Wait loop em `run_test_services.sh` (até 45s)
3. **Final**: Desativar ClamAV completamente

### Problema 4: smtpd "Bad Command Startup"

**Erro (logs)**:
```
postfix/master[332]: warning: /usr/lib/postfix/sbin/smtpd: 
  bad command startup -- throttling
```

**Causa**: Faltava `smtpd_relay_restrictions` no `main.cf`

**Solução**: Adicionar diretiva obrigatória
```conf
smtpd_relay_restrictions = 
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination
```

### Problema 5: Cliente Temporário Sem Rede

**Erro**: `docker-compose run --rm cliente` não conectava a `aasr_net`

**Causa**: Docker cria rede temporária para containers `run`

**Solução**: Tornar cliente persistente (ver Decisão #6)

### Problema 6: Postfix chroot Errors

**Erro**:
```
postfix/proxymap[365]: fatal: unix_trigger_event: cannot write to 
  /var/spool/postfix/public/pickup: Permission denied
```

**Causa**: Chroot ativo sem estrutura correta de jail

**Solução**: Desativar chroot em `master.cf`
```conf
# Service type private unpriv chroot wakeup maxproc
smtp      inet  n       -      n      -       -       smtpd
```

### Problema 7: LDAP Certificate Verification

**Erro (Postfix logs)**:
```
postfix/smtpd[436]: warning: ldaps://ldap:636: 
  TLS verify error: num=18:self signed certificate
```

**Causa**: Certificado autoassinado do Samba AD

**Solução**: Adicionar `tls_require_cert = never` em `ldap-*.cf`
```conf
tls_require_cert = never
```

### Problema 8: Amavis Lentidão Extrema

**Sintoma**: Startup SMTP > 2 minutos

**Causa**: ClamAV database load (400 MB) + freshclam sync

**Soluções tentadas**:
1. ❌ Otimizar freshclam mirrors
2. ❌ Pré-carregar database na image
3. ✅ **Desativar completamente** (ver Decisão #7)

### Problema 9: PostgreSQL Init Timeout

**Erro**: Container reiniciava antes de inicializar DB

**Causa**: `init.sql` com muitos dados levava >30s

**Solução**: Otimizar `init.sql` e aumentar healthcheck interval
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U app_user"]
  interval: 10s
  timeout: 5s
  retries: 5
```

### Problema 10: Firewall Logs Não Persistentes

**Sintoma**: Logs de iptables perdidos após restart

**Solução**: Configurar rsyslog forward para container `logs-ntp`
```conf
# Em firewall/rsyslog-forward.conf
*.* @logs-ntp:514
```

## 📊 Métricas de Performance

### Startup Times (segundos)

| Configuração | LDAP | Firewall | SMTP | Database | Logs-NTP | Total |
|--------------|------|----------|------|----------|----------|-------|
| **Com ClamAV** | 25 | 8 | **135** | 12 | 6 | **186** |
| **Sem ClamAV** | 25 | 8 | **20** | 12 | 6 | **71** |

### Consumo de RAM (MB)

| Container | Com ClamAV | Sem ClamAV |
|-----------|-----------|-----------|
| LDAP | 450 | 450 |
| Firewall | 180 | 180 |
| **SMTP** | **1200** | **400** |
| Database | 250 | 250 |
| Logs-NTP | 120 | 120 |
| Cliente | 80 | 80 |
| **Total** | **2280** | **1480** |

## 🔧 Configurações Críticas

### 1. smtpd_relay_restrictions (Postfix)
**Obrigatório** no Postfix moderno. Sem ele, `smtpd` não inicia.

### 2. inet_interfaces (Postfix)
```conf
inet_interfaces = all  # Escutar em todas as interfaces
```
**Alternativa**: `inet_interfaces = 0.0.0.0` (não funciona com Postfix)

### 3. mynetworks (Postfix)
```conf
mynetworks = 10.0.1.0/24, 127.0.0.0/8
```
Define quem pode fazer relay sem autenticação.

### 4. Samba Provision
```bash
samba-tool domain provision --use-rfc2307 --interactive
```
`--use-rfc2307`: Habilita POSIX attributes (uid, gid, shell)

### 5. ACL em volumes Docker
Montar volumes com `:rw` ou `:ro` conforme necessário:
```yaml
volumes:
  - ./scripts:/scripts:ro  # Read-only
  - ./backups:/backups     # Read-write (default)
```

## 🔥 Firewall em Ambiente Docker - Limitações Arquiteturais

### Contexto

O container `firewall` demonstra configuração de **iptables/Netfilter**, mas possui limitações inerentes à arquitetura Docker.

### O que o Firewall Faz ✅

1. **Protege o próprio container**:
   - Regras INPUT bloqueiam acesso não autorizado
   - SSH (porta 22) com controle de acesso
   - Logging de tentativas de conexão

2. **Protege o host**:
   - Tráfego da rede externa → host → containers passa pelo iptables do host
   - Portas mapeadas (2222:22, 2525:25) são filtradas

3. **Demonstra configuração funcional**:
   - 6 regras iptables ativas
   - Política de deny-by-default
   - Whitelist da rede 10.0.1.0/24

### O que o Firewall NÃO Faz ❌

**Tráfego inter-container NÃO passa pelo container firewall.**

```
Cliente (10.0.1.60) ──→ Docker Bridge (10.0.1.1) ──→ SMTP (10.0.1.30)
                            ↑ Roteamento direto
Firewall (10.0.1.20) ────────┘ NÃO intercepta
```

**Por quê?**
- Docker gerencia roteamento interno via bridge network
- Containers comunicam **diretamente** através do gateway (10.0.1.1)
- Não há rota default apontando para o container firewall

### Como Implementar Firewall Intermediário (Produção)

#### Opção 1: Network Policies (Kubernetes)
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-smtp-from-cliente
spec:
  podSelector:
    matchLabels:
      app: smtp
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: cliente
    ports:
    - protocol: TCP
      port: 25
```

#### Opção 2: Service Mesh (Istio/Linkerd)
- Proxy sidecar em cada container
- Controle de tráfego L7
- mTLS automático

#### Opção 3: Firewall como Gateway (Docker)
Configuração necessária:
```yaml
firewall:
  cap_add:
    - NET_ADMIN
  sysctls:
    - net.ipv4.ip_forward=1
```

```bash
# No firewall container
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -j ACCEPT
```

```yaml
# Outros containers
networks:
  aasr_net:
    ipv4_address: 10.0.1.30
    gateway: 10.0.1.20  # ← Firewall como gateway
```

**Não implementado porque:**
- Complexidade elevada
- Requer reconfiguração completa da rede
- Risco de quebrar outros serviços
- Docker já fornece isolamento de rede adequado

### Segurança Efetiva no Projeto

Apesar da limitação do firewall intermediário, o projeto possui **múltiplas camadas de segurança**:

1. **Isolamento de Rede** - Docker bridge customizada (10.0.1.0/24)
2. **Firewall no Host** - iptables protege portas expostas
3. **Autenticação LDAP** - Controle de acesso centralizado
4. **ACLs** - Permissões granulares por usuário/grupo
5. **Relay Restrictions (SMTP)** - Apenas rede confiável pode enviar
6. **SpamAssassin** - Filtragem de conteúdo malicioso

### Justificativa para Apresentação

**Argumento técnico:**
> "O container firewall demonstra configuração funcional de iptables/Netfilter. Em ambientes Docker de produção, a segmentação de rede entre containers é tipicamente implementada através de Network Policies (Kubernetes), Service Mesh (Istio), ou firewalls externos. O Docker já fornece isolamento de rede através da bridge customizada, e o projeto implementa múltiplas camadas de defesa (autenticação LDAP, ACLs, relay restrictions)."

**Se questionado sobre tráfego inter-container:**
> "Para implementar um firewall intermediário em Docker, seria necessário configurar o container firewall como gateway da rede (ip_forward, NAT, rotas default), o que adiciona complexidade significativa. Optei por demonstrar a configuração de iptables e focar em outras camadas de segurança que são mais relevantes em ambientes corporativos modernos."

## 🎓 Lições Aprendidas

1. **Start Simple, Add Complexity**: Começar com Postfix mínimo, depois adicionar features
2. **Logs são Essenciais**: 80% dos problemas resolvidos analisando `/var/log/mail.log`
3. **Docker Networking**: Entender diferença entre `run` e `exec` para testes
4. **Trade-offs Conscientes**: Performance vs Segurança (ClamAV desativado, mas justificado)
5. **Versionamento Completo**: Tudo no Git (configs, scripts, Dockerfiles)
6. **Documentação Progressiva**: Documentar problemas **durante** resolução, não depois
7. **Testes Automatizados**: Script `run_all_tests.sh` economiza horas de testes manuais
8. **Honestidade Técnica**: Documentar limitações é mais profissional que fingir que tudo é perfeito

## 📚 Referências

- [Postfix Documentation](http://www.postfix.org/documentation.html)
- [Samba Wiki](https://wiki.samba.org/)
- [Docker Networking](https://docs.docker.com/network/)
- [iptables Tutorial](https://www.netfilter.org/documentation/)
- [PostgreSQL Backup/Restore](https://www.postgresql.org/docs/current/backup.html)
