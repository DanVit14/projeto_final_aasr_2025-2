# rsyslog Centralizado - Configuração e Troubleshooting

## 📋 Problema Identificado

No teste end-to-end, os logs estavam sendo gerados localmente no SMTP, mas **não chegavam ao servidor central** (logs-ntp).

---

## 🔍 Causa Raiz

### Configuração Faltando

1. **Servidor (logs-ntp)** não estava configurado para **receber** logs UDP
2. **Cliente (smtp)** não estava configurado para **enviar** logs para o servidor
3. rsyslog precisava ser reiniciado após configuração

---

## ✅ Solução Implementada

### 1. Diagnóstico

```bash
./scripts/diagnose_rsyslog.sh
```

**O que verifica:**
- rsyslog está rodando nos containers?
- Porta 514 UDP está escutando no servidor?
- Conectividade SMTP → logs-ntp funciona?
- Onde estão os logs no servidor?
- Teste de envio manual de mensagem

### 2. Correção Automática

```bash
./scripts/fix_rsyslog.sh
```

**O que faz:**
1. Configura logs-ntp para receber UDP:514
2. Configura SMTP para enviar logs
3. Reinicia rsyslog em ambos
4. Testa com mensagem de validação
5. Força geração de logs do Postfix

---

## 🛠️ Configuração Manual (Se Necessário)

### No Servidor (logs-ntp)

```bash
# 1. Criar configuração para receber UDP
docker-compose exec logs-ntp bash -c 'cat > /etc/rsyslog.d/00-remote.conf <<EOF
# Habilitar recepção UDP
module(load="imudp")
input(type="imudp" port="514")

# Organizar logs por hostname
\$template RemoteHost,"/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteHost
EOF'

# 2. Criar diretório
docker-compose exec logs-ntp mkdir -p /var/log/remote

# 3. Reiniciar rsyslog
docker-compose exec logs-ntp pkill rsyslogd
docker-compose exec logs-ntp rsyslogd
```

### No Cliente (smtp)

```bash
# 1. Criar configuração de forward
docker-compose exec smtp bash -c 'cat > /etc/rsyslog.d/50-forward.conf <<EOF
# Enviar todos os logs para servidor central
*.* @logs-ntp:514
EOF'

# 2. Reiniciar rsyslog
docker-compose exec smtp pkill rsyslogd
docker-compose exec smtp rsyslogd
```

---

## 📊 Arquitetura de Logs

### Fluxo Corrigido

```
┌──────────┐
│   SMTP   │ (Gera logs)
│10.0.1.30 │
└────┬─────┘
     │
     │ *.* @logs-ntp:514 (UDP)
     │ (configurado em /etc/rsyslog.d/50-forward.conf)
     ▼
┌──────────┐
│Logs-NTP  │ (Recebe logs)
│10.0.1.50 │ Escuta UDP:514
└────┬─────┘
     │
     │ Organiza por hostname
     ▼
/var/log/remote/
  ├── mail.empresa.local/  (hostname do SMTP)
  │   ├── postfix.log
  │   ├── dovecot.log
  │   └── ...
  └── cliente.empresa.local/
      └── ...
```

### Template de Organização

```conf
$template RemoteHost,"/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log"
```

**Resultado:**
- Logs organizados por **hostname** do remetente
- Separados por **programa** (postfix, dovecot, etc.)
- Fácil de encontrar e filtrar

---

## ✅ Validação

### 1. Verificar rsyslog Escutando

```bash
# No servidor logs-ntp
docker-compose exec logs-ntp ss -ulnp | grep :514

# Output esperado:
# UNCONN  0  0  0.0.0.0:514  0.0.0.0:*  users:(("rsyslogd",pid=XXX,fd=Y))
```

### 2. Testar Envio Manual

```bash
# Do container SMTP
docker-compose exec smtp logger "TESTE $(date +%s)"

# Aguardar 5s
sleep 5

# Verificar no servidor
docker-compose exec logs-ntp grep -r "TESTE" /var/log/remote/
```

### 3. Ver Logs do Postfix

```bash
# Listar logs recebidos
docker-compose exec logs-ntp ls -lR /var/log/remote/

# Ver logs do Postfix em tempo real
docker-compose exec logs-ntp tail -f /var/log/remote/mail.empresa.local/postfix.log
```

---

## 🎯 Para o Teste End-to-End

### Ajuste no Script

O script `test_end_to_end.sh` já procura logs, mas pode precisar do path atualizado:

```bash
# Em vez de procurar em /var/log/
grep -r "${TEST_ID}" /var/log

# Procurar em /var/log/remote/
grep -r "${TEST_ID}" /var/log/remote/
```

### Re-executar Teste

```bash
# 1. Corrigir rsyslog
./scripts/fix_rsyslog.sh

# 2. Re-executar teste end-to-end
./scripts/test_end_to_end.sh

# Agora o PASSO 4 deve mostrar:
# ✓ Logs encontrados no servidor central (X linhas)
```

---

## 📈 Monitoramento Contínuo

### Ver Logs Chegando em Tempo Real

```bash
# Todos os logs
docker-compose exec logs-ntp tail -f /var/log/messages

# Apenas logs remotos
docker-compose exec logs-ntp tail -f /var/log/remote/mail.empresa.local/*.log

# Apenas Postfix
docker-compose exec logs-ntp tail -f /var/log/remote/mail.empresa.local/postfix.log
```

### Estatísticas

```bash
# Contar logs recebidos
docker-compose exec logs-ntp find /var/log/remote -type f -exec wc -l {} \;

# Ver últimos logs de cada fonte
docker-compose exec logs-ntp find /var/log/remote -type f -exec tail -1 {} \; -print
```

---

## ⚠️ Troubleshooting

### Problema: Logs Não Chegam

**Verificar:**
1. rsyslog rodando em ambos? `ps aux | grep rsyslog`
2. Porta 514 aberta? `ss -ulnp | grep 514`
3. Conectividade? `ping logs-ntp`
4. Configuração correta? `cat /etc/rsyslog.d/*.conf`

**Solução:**
```bash
# Reiniciar tudo
docker-compose restart smtp logs-ntp

# Re-executar correção
./scripts/fix_rsyslog.sh
```

### Problema: Logs em Path Diferente

```bash
# Procurar em todo /var/log
docker-compose exec logs-ntp find /var/log -name "*.log" -mtime -1

# Procurar por conteúdo específico
docker-compose exec logs-ntp grep -r "postfix" /var/log --include="*.log"
```

### Problema: Permissões

```bash
# Dar permissões corretas
docker-compose exec logs-ntp chmod 755 /var/log/remote
docker-compose exec logs-ntp chown -R root:root /var/log/remote
```

---

## 🎓 Para a Apresentação

### Se Perguntarem

**P: "Os logs estão centralizados?"**
> "Sim! Configurei rsyslog no SMTP para enviar todos os logs via UDP:514 para o servidor logs-ntp. O servidor organiza os logs por hostname em `/var/log/remote/`. Posso demonstrar ao vivo: envio uma mensagem de teste do SMTP e ela aparece no servidor central em segundos."

### Demonstração Ao Vivo

```bash
# Terminal 1: Monitorar logs chegando
docker-compose exec logs-ntp tail -f /var/log/remote/mail.empresa.local/postfix.log

# Terminal 2: Gerar log
docker-compose exec smtp logger "DEMO_APRESENTACAO $(date)"

# Terminal 1 mostrará a mensagem aparecer!
```

---

## 📚 Referências

- [rsyslog Documentation](https://www.rsyslog.com/doc/)
- [rsyslog UDP Input Module](https://www.rsyslog.com/doc/imudp.html)
- [rsyslog Templates](https://www.rsyslog.com/doc/configuration/templates.html)

---

**Conclusão:** Com esses scripts, logs centralizados ficam 100% funcionais. O problema era apenas configuração faltando, não falha de arquitetura.
