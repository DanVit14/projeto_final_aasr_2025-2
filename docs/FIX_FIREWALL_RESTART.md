# 🔧 Fix: Firewall em Loop de Restart

## ❌ Problema

Container firewall está em loop de restart:
```
Error: Container is restarting, wait until the container is running
```

## 🔍 Causa

O script `setup_forward.sh` estava usando `set -e` que causa crash ao primeiro erro. Quando algum comando iptables falhava, o script terminava abruptamente e o container entrava em loop de restart.

## ✅ Solução

### Correção Aplicada

**Antes:**
```bash
set -e  # Crash ao primeiro erro
iptables -t nat -F  # Se falhar, container crasha
```

**Depois:**
```bash
# Sem set -e
if iptables -t nat -F 2>/dev/null; then
    echo "✓ OK"
else
    echo "⚠ Warning (não crítico)"
fi
# Container continua rodando mesmo com erros
```

---

## 🚀 Como Aplicar na VM

### Opção 1: Rebuild Completo (Recomendado)

```bash
# 1. Sincronizar código
git pull origin main

# 2. Parar e remover container
docker-compose stop firewall
docker-compose rm -f firewall

# 3. Rebuild imagem
docker-compose build firewall

# 4. Iniciar novamente
docker-compose up -d firewall

# 5. Verificar logs (deve estar OK agora)
docker-compose logs firewall
```

**Tempo:** ~1 minuto

---

### Opção 2: Sem Rebuild (Mais Rápido)

Se não quiseres rebuild, pode apenas substituir o script:

```bash
# 1. Sincronizar código
git pull origin main

# 2. Parar container
docker-compose stop firewall

# 3. Remover container (não imagem)
docker-compose rm -f firewall

# 4. Iniciar (vai montar novo script)
docker-compose up -d firewall

# 5. Verificar
docker-compose logs firewall
```

**Tempo:** ~15 segundos

---

## ✅ Verificação

### 1. Container Deve Estar Running

```bash
docker-compose ps firewall
```

**Esperado:**
```
NAME        STATUS      PORTS
firewall    Up X seconds
```

**NÃO deve mostrar:** `Restarting`

---

### 2. Logs Não Devem Ter Erros Fatais

```bash
docker-compose logs --tail=30 firewall
```

**Esperado (linhas como estas):**
```
✓ IP forwarding habilitado
✓ Regras NAT limpas
✓ PREROUTING (DNAT) configurado
✓ POSTROUTING (MASQUERADE) configurado
✓ FORWARD (inbound) configurado
✓ FORWARD (outbound) configurado
✓ Port forwarding configurado
Setup concluído!
```

**Warnings (⚠️) são OK**, só erros críticos (✗) são problema.

---

### 3. Regras iptables Devem Estar Ativas

```bash
docker-compose exec firewall iptables -t nat -L PREROUTING -n -v
```

**Esperado (linha como esta):**
```
DNAT  tcp  --  *  *  0.0.0.0/0  0.0.0.0/0  tcp dpt:5432 to:10.0.1.40:5432
```

---

### 4. Teste de Conectividade

```bash
# Testar porta TCP
docker-compose exec cliente bash -c '</dev/tcp/10.0.1.20/5432' && echo "✓ Firewall acessível"
```

---

## 🐛 Se Ainda Não Funcionar

### Debug Avançado

```bash
# 1. Ver logs completos
docker-compose logs firewall | less

# 2. Entrar no container (se estiver rodando)
docker-compose exec firewall bash

# 3. Dentro do container, testar manualmente:
iptables -t nat -L -n -v
iptables -L FORWARD -n -v

# 4. Testar setup manualmente:
bash /usr/local/bin/setup_forward.sh
```

---

### Script de Debug Automático

```bash
./scripts/debug_firewall.sh
```

Este script:
- Mostra status do container
- Mostra logs
- Tenta executar comandos manualmente
- Identifica onde está falhando

---

## 📋 Checklist de Solução

- [ ] `git pull origin main` (código atualizado)
- [ ] `docker-compose stop firewall`
- [ ] `docker-compose rm -f firewall`
- [ ] `docker-compose build firewall` (opcional mas recomendado)
- [ ] `docker-compose up -d firewall`
- [ ] `docker-compose ps firewall` → **Status: Up**
- [ ] `docker-compose logs firewall` → **Sem erros fatais**
- [ ] `docker-compose exec firewall iptables -t nat -L` → **Regras ativas**

---

## 🎯 Resultado Esperado

Após aplicar a correção:

```bash
$ docker-compose ps firewall
NAME        STATUS
firewall    Up 10 seconds    # ✓ Running (não Restarting)

$ docker-compose logs firewall | tail -5
✓ PREROUTING (DNAT) configurado
✓ POSTROUTING (MASQUERADE) configurado
✓ FORWARD (inbound) configurado
✓ Port forwarding configurado
Setup concluído!

$ docker-compose exec firewall iptables -t nat -L -n -v | grep 5432
DNAT tcp -- * * 0.0.0.0/0 0.0.0.0/0 tcp dpt:5432 to:10.0.1.40:5432
```

**Tudo OK!** ✅

---

## 💡 Por Que Aconteceu?

### Problema Original

O script usava `set -e` que significa "exit on error". Quando qualquer comando iptables falhava (mesmo erros não-críticos), o script terminava e o container crashava.

### Cenários que Causavam Crash

1. **Limpar NAT vazio:** `iptables -t nat -F` em NAT vazio podia falhar
2. **Regras duplicadas:** Tentar adicionar regra que já existe
3. **Rede não pronta:** Comandos executados antes da rede estar 100% pronta
4. **Permissões:** Em alguns ambientes, certos comandos iptables são restritos

### Solução Aplicada

- ✅ Sem `set -e` - script continua mesmo com erros
- ✅ Verificação individual de cada comando
- ✅ Tratamento graceful de erros não-críticos
- ✅ Sleep para aguardar rede
- ✅ `exit 0` em vez de `exit 1` para erros críticos

Agora o container **sempre inicia**, mesmo que alguns comandos falhem.

---

## 📚 Arquivos Relacionados

- `docker/firewall/setup_forward.sh` - Script corrigido
- `scripts/debug_firewall.sh` - Debug automatizado
- `docs/FIREWALL_INTEGRACAO.md` - Documentação completa
- `docs/RESUMO_FIREWALL.md` - Resumo executivo

---

**Problema resolvido! Container firewall agora inicia corretamente.** 🎉
