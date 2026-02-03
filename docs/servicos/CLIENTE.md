# Cliente (Teste)

## 📋 Visão Geral

**Função:** Container de testes e simulação de cliente corporativo  
**IP:** 10.0.1.60  
**Container:** cliente_teste  
**Imagem Base:** Debian 11

---

## 🔧 Configuração

### Ferramentas Instaladas

- **psql:** Cliente PostgreSQL
- **ldap-utils:** ldapsearch, ldapwhoami
- **sendmail:** Envio de emails
- **netcat (nc):** Testes de conectividade
- **curl, wget:** Downloads
- **ping, telnet:** Diagnóstico de rede

### Restart Policy

```yaml
restart: unless-stopped
command: sleep infinity
```

Container fica rodando infinitamente para executar comandos.

---

## 🚀 Uso

### Executar Comandos

```bash
# Entrar no container
docker-compose exec cliente bash

# Executar comando direto
docker-compose exec cliente [comando]
```

### Exemplos de Uso

#### 1. Testar LDAP
```bash
docker-compose exec cliente ldapsearch -x -H ldap://ldap \
  -b "DC=empresa,DC=local" "(objectClass=user)"
```

#### 2. Enviar Email
```bash
docker-compose exec cliente sendmail user1@empresa.local <<EOF
From: admin@empresa.local
Subject: Teste

Mensagem de teste.
EOF
```

#### 3. Testar Database (Direto)
```bash
docker-compose exec cliente psql -h 10.0.1.40 -U app_user -d empresa_db \
  -c "SELECT NOW();"
```

#### 4. Testar Database (Via Firewall)
```bash
docker-compose exec cliente psql -h 10.0.1.20 -U app_user -d empresa_db \
  -c "SELECT NOW();"
```

#### 5. Testar Conectividade TCP
```bash
# SMTP
docker-compose exec cliente nc -zv smtp 25

# LDAP
docker-compose exec cliente nc -zv ldap 389

# Database via firewall
docker-compose exec cliente bash -c '</dev/tcp/10.0.1.20/5432'
```

#### 6. Enviar Log para Servidor Central
```bash
docker-compose exec cliente logger "Teste de log do cliente"
```

---

## 📜 Scripts de Teste

O cliente é usado para executar todos os scripts de teste:

### Teste End-to-End
```bash
docker-compose exec cliente /usr/local/bin/test_services.sh
# ou
./scripts/test_end_to_end.sh
```

### Teste de Serviços Básicos
```bash
docker-compose exec cliente /usr/local/bin/test_services.sh
# ou
./scripts/test_services.sh
```

---

## 🔗 Conectividade

### Hosts Acessíveis

| Host | IP | Porta(s) |
|------|---------|----------|
| ldap | 10.0.1.30 | 389, 636 |
| smtp | 10.0.1.30 | 25 |
| database | 10.0.1.40 | 5432 |
| firewall | 10.0.1.20 | 5432 (forward) |
| logs-ntp | 10.0.1.50 | 123/udp, 514/udp |

### Resolução de Nomes

Docker fornece DNS automático:
```bash
# Por nome do serviço
ping ldap
ping smtp
ping database

# Por hostname
ping ldap.empresa.local
ping mail.empresa.local
ping db.empresa.local
```

---

## ✅ Validação

### Verificar Conectividade com Todos os Serviços

```bash
# LDAP
docker-compose exec cliente nc -zv ldap 389 && echo "✓ LDAP OK"

# SMTP  
docker-compose exec cliente nc -zv smtp 25 && echo "✓ SMTP OK"

# Database
docker-compose exec cliente nc -zv database 5432 && echo "✓ Database OK"

# Firewall (port forward)
docker-compose exec cliente bash -c '</dev/tcp/10.0.1.20/5432' && echo "✓ Firewall OK"

# NTP
docker-compose exec cliente nc -zuv logs-ntp 123 && echo "✓ NTP OK"
```

---

## 🛠️ Troubleshooting

### Container Não Inicia

**Ver logs:**
```bash
docker-compose logs cliente
```

**Reiniciar:**
```bash
docker-compose restart cliente
```

### Comando Não Encontrado

**Instalar ferramenta:**
```bash
# Entrar no container
docker-compose exec cliente bash

# Atualizar apt
apt-get update

# Instalar ferramenta
apt-get install -y [pacote]
```

### Sem Conectividade

**Verificar rede:**
```bash
# IP do cliente
docker-compose exec cliente ip addr show eth0

# Ping para gateway
docker-compose exec cliente ping -c 2 10.0.1.1

# DNS funciona?
docker-compose exec cliente nslookup ldap
```

---

## 📁 Arquivos Relacionados

- `docker/cliente/Dockerfile`
- `scripts/test_services.sh` (montado no container)
- `scripts/test_end_to_end.sh` (executado do host)

---

**Cliente: Ponto de partida para todos os testes e simulação de usuário final.** ✅
