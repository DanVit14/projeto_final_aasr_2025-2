# Scripts de Teste - Guia Rápido

## 📋 Scripts Disponíveis

### 1. `test_firewall_simples.sh` ⭐ **RECOMENDADO**
**Uso:** Teste rápido do firewall (sem psql, não trava)

**O que faz:**
- ✅ Mostra regras iptables (NAT + FORWARD)
- ✅ Testa conectividade TCP via firewall
- ✅ Gera múltiplas conexões
- ✅ Verifica logs do kernel
- ✅ Mostra contadores de pacotes

**Tempo:** ~15 segundos

```bash
./scripts/test_firewall_simples.sh
```

---

### 2. `test_firewall_forward.sh`
**Uso:** Teste completo do firewall (pode travar no psql)

**O que faz:**
- ✅ Tudo do `test_firewall_simples.sh`
- ⚠️ Tenta executar query SQL (pode travar se psql não instalado)

**Tempo:** ~30-60 segundos (ou trava)

```bash
./scripts/test_firewall_forward.sh
```

**Nota:** Se travar no PASSO 4, pressione Ctrl+C

---

### 3. `show_firewall_rules.sh`
**Uso:** Apenas mostrar regras iptables

**O que faz:**
- Exibe regras NAT (PREROUTING, POSTROUTING)
- Exibe regras FORWARD
- Procura por porta 5432

**Tempo:** ~5 segundos

```bash
./scripts/show_firewall_rules.sh
```

---

### 4. `test_end_to_end.sh`
**Uso:** Teste completo de integração (todos os 6 serviços)

**O que faz:**
1. LDAP autenticação
2. SMTP envio de email
3. Maildir entrega
4. Logs centralizados
5. Database auditoria
6. Query auditoria

**Tempo:** ~30-60 segundos

```bash
./scripts/test_end_to_end.sh
```

---

### 5. `fix_rsyslog.sh`
**Uso:** Corrigir logs centralizados (se não funcionarem)

```bash
./scripts/fix_rsyslog.sh
```

---

### 6. `diagnose_rsyslog.sh`
**Uso:** Diagnosticar problemas de rsyslog

```bash
./scripts/diagnose_rsyslog.sh
```

---

### 7. `debug_firewall.sh`
**Uso:** Debug do container firewall (se não iniciar)

```bash
./scripts/debug_firewall.sh
```

---

## 🎯 Qual Script Usar?

### Para Apresentação
```bash
# 1. Firewall (rápido e visual)
./scripts/test_firewall_simples.sh

# 2. Teste completo (todos serviços)
./scripts/test_end_to_end.sh
```

### Para Debug
```bash
# Se firewall não inicia
./scripts/debug_firewall.sh

# Se logs não centralizam
./scripts/diagnose_rsyslog.sh
```

### Para Evidências
```bash
# Capturar output para arquivo
./scripts/test_firewall_simples.sh > docs/EVIDENCIAS/firewall_teste.txt
./scripts/test_end_to_end.sh > docs/EVIDENCIAS/teste_end_to_end.txt
```

---

## 🚀 Testes Rápidos (Linha de Comando)

### Firewall
```bash
# Ver regras NAT
docker-compose exec firewall iptables -t nat -L PREROUTING -n -v

# Testar conectividade
docker-compose exec cliente bash -c '</dev/tcp/10.0.1.20/5432' && echo "✓ OK"

# Ver logs
docker-compose exec firewall dmesg | grep FW-DB
```

### Logs Centralizados
```bash
# Ver estrutura
docker-compose exec logs-ntp ls -lR /var/log/remote/

# Ver logs do SMTP
docker-compose exec logs-ntp tail -20 /var/log/remote/mail/all.log
```

### Database
```bash
# Ver auditoria
docker-compose exec database psql -U app_user -d empresa_db -c "SELECT * FROM audit_log ORDER BY timestamp DESC LIMIT 5;"
```

---

## 📊 Matriz de Scripts

| Script | Tempo | Pode Travar? | Para Apresentação? | Para Debug? |
|--------|-------|--------------|-------------------|-------------|
| `test_firewall_simples.sh` | 15s | ❌ Não | ✅ **Sim** | ✅ Sim |
| `test_firewall_forward.sh` | 30s+ | ⚠️ Sim | ⚠️ Cuidado | ✅ Sim |
| `show_firewall_rules.sh` | 5s | ❌ Não | ✅ Sim | ✅ Sim |
| `test_end_to_end.sh` | 60s | ❌ Não | ✅ **Sim** | ✅ Sim |
| `fix_rsyslog.sh` | 30s | ❌ Não | ❌ Não | ✅ **Sim** |
| `diagnose_rsyslog.sh` | 20s | ❌ Não | ❌ Não | ✅ **Sim** |
| `debug_firewall.sh` | 15s | ❌ Não | ❌ Não | ✅ **Sim** |

---

## 💡 Dicas

### Se Script Travar
1. Pressione **Ctrl+C**
2. Verifique qual PASSO travou
3. Execute manualmente esse passo
4. Use script alternativo (`test_firewall_simples.sh`)

### Para Apresentação
1. **Preparar antes:**
   ```bash
   ./scripts/test_firewall_simples.sh
   ./scripts/test_end_to_end.sh
   ```

2. **Durante apresentação:**
   - Mostrar outputs salvos
   - Executar comandos individuais ao vivo
   - Usar `show_firewall_rules.sh` (rápido)

---

## 📚 Documentação Relacionada

- `docs/GUIA_TESTE_E2E.md` - Guia completo dos testes
- `docs/FIREWALL_INTEGRACAO.md` - Como firewall funciona
- `docs/RESUMO_FIREWALL.md` - Resumo executivo
- `docs/RSYSLOG_CENTRALIZADO.md` - Logs centralizados
- `docs/FIX_FIREWALL_RESTART.md` - Resolver loop de restart

---

**Prioridade para apresentação: `test_firewall_simples.sh` + `test_end_to_end.sh`** ⭐
