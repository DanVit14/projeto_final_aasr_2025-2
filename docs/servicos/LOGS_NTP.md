# Logs-NTP (Rsyslog + Chrony)

## 📋 Visão Geral

**Função:** Logs centralizados + sincronização de tempo  
**IP:** 10.0.1.50  
**Container:** logs-ntp  
**Software:** Rsyslog + Chrony (NTP)

---

## 🔧 Configuração

### Portas

| Porta Host | Porta Container | Serviço |
|------------|-----------------|---------|
| 123/udp | 123/udp | NTP |
| - | 514/udp | Rsyslog |

### Volumes

- **Logs remotos:** `logs_data:/var/log/remote`
- **Configs:** `rsyslog.conf`, `chrony.conf`

---

## 📝 Rsyslog (Logs Centralizados)

### Funcionamento

1. Recebe logs via UDP:514
2. Organiza por hostname em `/var/log/remote/[hostname]/`
3. Separa por programa (postfix.log, dovecot.log, etc.)

### Estrutura de Logs

```
/var/log/remote/
├── mail.empresa.local/    (hostname do SMTP)
│   ├── postfix.log
│   ├── dovecot.log
│   └── logger.log
├── cliente.empresa.local/
│   └── ...
└── all.log                (consolidado)
```

### Configuração

```conf
# Habilitar recepção UDP
module(load="imudp")
input(type="imudp" port="514")

# Template de organização
$template RemoteHost,"/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteHost
```

---

## ✅ Validação (Rsyslog)

### Ver Estrutura de Logs

```bash
docker-compose exec logs-ntp ls -lR /var/log/remote/
```

### Ver Logs do SMTP

```bash
# Ver últimos logs do Postfix
docker-compose exec logs-ntp tail -20 /var/log/remote/mail.empresa.local/postfix.log

# ou (se caminho diferir)
docker-compose exec logs-ntp tail -20 /var/log/remote/mail/all.log
```

### Monitorar em Tempo Real

```bash
docker-compose exec logs-ntp tail -f /var/log/remote/mail/all.log
```

### Testar Envio de Log

```bash
# Do cliente
docker-compose exec cliente logger "TESTE $(date +%s)"

# Aguardar 3s
sleep 3

# Verificar no servidor
docker-compose exec logs-ntp grep "TESTE" /var/log/remote -r
```

---

## 🕐 NTP (Sincronização de Tempo)

### Funcionamento

Servidor NTP para sincronizar relógios dos containers.

### Validação

```bash
# Status do chrony
docker-compose exec logs-ntp chronyc tracking

# Ver fontes de tempo
docker-compose exec logs-ntp chronyc sources

# Estatísticas
docker-compose exec logs-ntp chronyc sourcestats
```

### Saída Esperada

```
Reference ID    : A9FEA97B (169.254.169.123)
Stratum         : 4
Ref time (UTC)  : Mon Feb 03 19:00:00 2026
System time     : 0.000000000 seconds fast of NTP time
Last offset     : +0.000123456 seconds
RMS offset      : 0.001234567 seconds
```

---

## 🛠️ Troubleshooting

### Logs Não Chegam

**Diagnosticar:**
```bash
./scripts/diagnose_rsyslog.sh
```

**Corrigir:**
```bash
./scripts/fix_rsyslog.sh
```

**Verificações:**

1. rsyslog escutando UDP:514?
   ```bash
   docker-compose exec logs-ntp ss -ulnp | grep 514
   ```

2. Clientes configurados para enviar?
   ```bash
   docker-compose exec smtp cat /etc/rsyslog.d/50-forward.conf
   # Deve ter: *.* @logs-ntp:514
   ```

3. Conectividade?
   ```bash
   docker-compose exec smtp ping -c 2 logs-ntp
   ```

### NTP Não Sincroniza

**Verificar:**
```bash
# Chrony rodando?
docker-compose exec logs-ntp ps aux | grep chronyd

# Ver tracking
docker-compose exec logs-ntp chronyc tracking

# Reiniciar se necessário
docker-compose restart logs-ntp
```

### Disco Cheio (Logs)

**Ver tamanho:**
```bash
docker-compose exec logs-ntp du -sh /var/log/remote/
```

**Limpar logs antigos:**
```bash
docker-compose exec logs-ntp find /var/log/remote/ -name "*.log" -mtime +30 -delete
```

**Rotação automática:**
Configurar logrotate no container (opcional).

---

## 📁 Arquivos Relacionados

- `docker/logs-ntp/Dockerfile`
- `docker/logs-ntp/rsyslog.conf`
- `docker/logs-ntp/chrony.conf`
- `scripts/diagnose_rsyslog.sh`
- `scripts/fix_rsyslog.sh`
- `scripts/test_ntp.sh`

---

**Logs-NTP: Centralização de logs e sincronização de tempo para todo o ambiente.** ✅
