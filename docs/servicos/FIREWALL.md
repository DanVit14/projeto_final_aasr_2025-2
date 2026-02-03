# Firewall

## 📋 Visão Geral

**Função:** Proteção de rede e port forwarding  
**IP:** 10.0.1.20  
**Container:** firewall  
**Imagem Base:** Debian 11

---

## 🔧 Configuração

### Características

- **iptables** para regras de firewall
- **Port Forwarding (DNAT)** para PostgreSQL
- **Logging** de conexões
- **Capabilities:** NET_ADMIN, NET_RAW

### Portas Expostas

| Porta Host | Porta Container | Serviço |
|------------|-----------------|---------|
| 2222 | 22 | SSH |
| 5433 | 5432 | PostgreSQL via firewall |

---

## 🚀 Port Forwarding (DNAT)

### Regras Configuradas

```bash
# PREROUTING: Redirecionar 5432 → database
iptables -t nat -A PREROUTING -p tcp --dport 5432 \
  -j DNAT --to-destination 10.0.1.40:5432

# POSTROUTING: Mascarar origem
iptables -t nat -A POSTROUTING -p tcp -d 10.0.1.40 --dport 5432 \
  -j MASQUERADE

# FORWARD: Permitir tráfego
iptables -A FORWARD -p tcp -d 10.0.1.40 --dport 5432 -j ACCEPT
iptables -A FORWARD -p tcp -s 10.0.1.40 --sport 5432 -j ACCEPT

# LOG: Registrar conexões
iptables -A FORWARD -p tcp --dport 5432 \
  -j LOG --log-prefix "[FW-DB] " --log-level 4
```

### Fluxo de Tráfego

```
Cliente → Firewall:5432
    ↓ (DNAT)
Database:5432
    ↓ (processa)
Database → Firewall
    ↓ (reverte NAT)
Firewall → Cliente
```

---

## ✅ Validação

### Ver Regras

```bash
# Regras NAT (port forward)
docker-compose exec firewall iptables -t nat -L PREROUTING -n -v

# Regras FORWARD
docker-compose exec firewall iptables -L FORWARD -n -v

# Script automático
./scripts/show_firewall_rules.sh
```

### Testar Conectividade

```bash
# Do cliente via firewall
docker-compose exec cliente bash -c '</dev/tcp/10.0.1.20/5432'

# Esperado: Conexão bem-sucedida (exit code 0)
```

### Ver Logs

```bash
# Logs do kernel (iptables LOG)
docker-compose exec firewall dmesg | grep "FW-DB"

# Últimas conexões
docker-compose exec firewall dmesg | grep "FW-DB" | tail -10
```

### Verificar Contadores

```bash
# Quantos pacotes passaram
docker-compose exec firewall iptables -t nat -L PREROUTING -n -v

# Procurar coluna 'pkts' (deve ser > 0 após teste)
```

---

## 🛠️ Troubleshooting

### Container em Loop de Restart

**Sintoma:**
```
Container is restarting, wait until the container is running
```

**Solução:**
```bash
docker-compose stop firewall
docker-compose rm -f firewall
docker-compose build firewall
docker-compose up -d firewall
```

**Script de Debug:**
```bash
./scripts/debug_firewall.sh
```

### Regras Não Aplicadas

**Verificar:**
```bash
# Ver logs de startup
docker-compose logs firewall | grep "Setup concluído"

# Se não apareceu, executar manualmente
docker-compose exec firewall bash /usr/local/bin/setup_forward.sh
```

### Port Forward Não Funciona

**Diagnosticar:**
```bash
# 1. Regras estão ativas?
docker-compose exec firewall iptables -t nat -L -n -v | grep 5432

# 2. IP forwarding habilitado?
docker-compose exec firewall cat /proc/sys/net/ipv4/ip_forward
# Esperado: 1

# 3. Database acessível?
docker-compose exec firewall ping -c 2 10.0.1.40
```

---

## ⚠️ Limitações

### Tráfego Inter-Container

**Problema:** Containers na mesma rede Docker comunicam diretamente, não passam pelo firewall.

**Exemplo:**
```
SMTP → Database (direto, não passa pelo firewall)
LDAP → Database (direto, não passa pelo firewall)
```

**Motivo:** Arquitetura do Docker networking (bridge network).

**Solução Implementada:** Port forwarding explícito para demonstração.

**Produção:** Kubernetes Network Policies ou Service Mesh (Istio, Linkerd).

---

## 📊 Para Apresentação

### Demonstração Rápida

```bash
# 1. Mostrar regras
docker-compose exec firewall iptables -t nat -L PREROUTING -n -v

# 2. Destacar DNAT e contadores
# pkts > 0 significa que tráfego passou

# 3. Explicar:
# "O firewall está configurado para fazer port forwarding usando DNAT.
# Quando o cliente se conecta na porta 5432 do firewall, o tráfego é
# redirecionado para o database. Os contadores mostram que X pacotes
# já passaram por essa regra."
```

### Script de Teste

```bash
# Teste completo (sem psql, não trava)
./scripts/test_firewall_apenas_regras.sh
```

---

## 📁 Arquivos Relacionados

- `docker/firewall/Dockerfile`
- `docker/firewall/firewall.sh` (startup script)
- `docker/firewall/setup_forward.sh` (configura DNAT)
- `docker/firewall/iptables.rules` (regras base)
- `scripts/show_firewall_rules.sh`
- `scripts/test_firewall_apenas_regras.sh`
- `scripts/debug_firewall.sh`

---

**Firewall: Integrado no fluxo via port forwarding, com logging de conexões.** ✅
