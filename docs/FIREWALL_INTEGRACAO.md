# Firewall - Integração no Fluxo de Dados

## 🎯 Objetivo

Integrar o container firewall **ativamente** no fluxo end-to-end, demonstrando que ele não apenas existe na rede, mas **processa tráfego real** entre serviços.

---

## 📊 Solução Implementada

### Port Forwarding (DNAT)

O firewall atua como **proxy transparente** para o PostgreSQL:

```
┌────────────┐         ┌────────────┐         ┌────────────┐
│  CLIENTE   │ ------> │  FIREWALL  │ ------> │  DATABASE  │
│ 10.0.1.60  │  5432   │ 10.0.1.20  │  5432   │ 10.0.1.40  │
└────────────┘         └────────────┘         └────────────┘
                       (DNAT + LOG)
```

### Funcionamento Técnico

#### 1. Cliente se Conecta ao Firewall
```bash
psql -h 10.0.1.20 -U app_user -d empresa_db
```
Cliente pensa que está se conectando diretamente ao PostgreSQL.

#### 2. Firewall Aplica Regras iptables

**PREROUTING (NAT):**
```bash
iptables -t nat -A PREROUTING -p tcp --dport 5432 \
  -j DNAT --to-destination 10.0.1.40:5432
```
**Efeito:** Redireciona pacotes destinados a `firewall:5432` para `database:5432`

**POSTROUTING (NAT):**
```bash
iptables -t nat -A POSTROUTING -p tcp -d 10.0.1.40 --dport 5432 \
  -j MASQUERADE
```
**Efeito:** Database vê o firewall como origem, responde de volta ao firewall

**FORWARD (Filtro):**
```bash
iptables -A FORWARD -p tcp -d 10.0.1.40 --dport 5432 -j ACCEPT
iptables -A FORWARD -p tcp -s 10.0.1.40 --sport 5432 -j ACCEPT
```
**Efeito:** Permite tráfego forwarded para/do database

**LOG (Auditoria):**
```bash
iptables -A FORWARD -p tcp --dport 5432 \
  -j LOG --log-prefix "[FW-DB] " --log-level 4
```
**Efeito:** Registra todas as conexões PostgreSQL em logs do kernel

#### 3. Database Processa Query
Database recebe conexão como se viesse do firewall (graças ao MASQUERADE).

#### 4. Resposta Volta pelo Mesmo Caminho
```
DATABASE → FIREWALL → CLIENTE
```
Firewall mantém tabela de conexões (conntrack) e roteia resposta corretamente.

---

## 🛠️ Configuração Automática

### Script de Setup

**Arquivo:** `docker/firewall/setup_forward.sh`

**Executado automaticamente** durante inicialização do container:

```bash
# Em firewall.sh (startup do container)
if [ -f /usr/local/bin/setup_forward.sh ]; then
    bash /usr/local/bin/setup_forward.sh
fi
```

### Docker Compose

**Volumes adicionados:**
```yaml
firewall:
  volumes:
    - ./docker/firewall/setup_forward.sh:/usr/local/bin/setup_forward.sh:ro
  ports:
    - "5433:5432"  # Expor no host também (opcional)
```

---

## ✅ Validação

### Teste Automatizado

```bash
./scripts/test_firewall_forward.sh
```

**O script verifica:**
1. ✅ Regras NAT configuradas
2. ✅ Conectividade via firewall funciona
3. ✅ Query PostgreSQL via firewall executada
4. ✅ Logs registrados no firewall
5. ✅ Contadores de pacotes incrementados

### Teste Manual

#### Passo 1: Verificar Regras
```bash
docker-compose exec firewall iptables -t nat -L -n -v
```

**Buscar por:**
```
Chain PREROUTING (policy ACCEPT X packets, Y bytes)
 pkts bytes target     prot opt in     out     source        destination
    Z  ZZZ DNAT       tcp  --  *      *       0.0.0.0/0     0.0.0.0/0    tcp dpt:5432 to:10.0.1.40:5432
```

#### Passo 2: Testar Conectividade
```bash
# Do container cliente
docker-compose exec cliente bash -c '</dev/tcp/10.0.1.20/5432'
echo $?  # Deve retornar 0 (sucesso)
```

#### Passo 3: Executar Query
```bash
docker-compose exec cliente psql -h 10.0.1.20 -U app_user -d empresa_db \
  -c "SELECT 'Conexão via firewall OK!' as status;"
```

**Saída esperada:**
```
         status          
-------------------------
 Conexão via firewall OK!
(1 row)
```

#### Passo 4: Ver Logs
```bash
# Ver logs do kernel (iptables LOG)
docker-compose exec firewall dmesg | grep "FW-DB"

# Ou ver logs do sistema
docker-compose exec firewall tail -f /var/log/kern.log | grep "FW-DB"
```

**Saída esperada:**
```
[FW-DB] IN=eth0 OUT=eth0 SRC=10.0.1.60 DST=10.0.1.40 PROTO=TCP SPT=XXXXX DPT=5432
```

#### Passo 5: Monitorar em Tempo Real
```bash
# Terminal 1: Monitorar logs
docker-compose exec firewall dmesg -w | grep --line-buffered "FW-DB"

# Terminal 2: Executar query
docker-compose exec cliente psql -h 10.0.1.20 -U app_user -d empresa_db -c "SELECT NOW();"

# Terminal 1 mostrará logs aparecendo!
```

---

## 📊 Evidências para Apresentação

### 1. Diagrama de Fluxo
```
ANTES (sem firewall):
  Cliente ------> Database (direto)

DEPOIS (com firewall):
  Cliente ------> Firewall ------> Database
                 (NAT+LOG)
```

### 2. Demonstração Ao Vivo

**Roteiro:**

1. **Mostrar regras iptables:**
   ```bash
   docker-compose exec firewall iptables -t nat -L PREROUTING -n -v
   ```
   > "Vejam aqui, o firewall está configurado para fazer DNAT: qualquer conexão na porta 5432 é redirecionada para o database em 10.0.1.40."

2. **Executar query via firewall:**
   ```bash
   docker-compose exec cliente psql -h 10.0.1.20 -U app_user -d empresa_db -c "SELECT 'Via Firewall!' as msg;"
   ```
   > "Estou me conectando ao firewall (10.0.1.20), mas a query é processada no database (10.0.1.40). O firewall faz o proxy transparente."

3. **Mostrar logs:**
   ```bash
   docker-compose exec firewall dmesg | grep "FW-DB" | tail -5
   ```
   > "E aqui estão os logs: o firewall registrou minha conexão. Isso prova que o tráfego passou por ele!"

4. **Mostrar contadores:**
   ```bash
   docker-compose exec firewall iptables -L FORWARD -n -v | grep 5432
   ```
   > "Veja os contadores de pacotes: X pacotes processados pela regra do PostgreSQL."

### 3. Responder Perguntas Comuns

**P: "O firewall está realmente ativo no projeto?"**
> "Sim! O firewall não apenas existe na rede, ele processa tráfego real. Implementei port forwarding (DNAT) para que o cliente acesse o database através do firewall. Posso demonstrar executando uma query que passa pelo firewall e verificando os logs."

**P: "Por que não bloqueia tráfego entre containers?"**
> "Essa é uma limitação arquitetural do Docker. Containers na mesma rede bridge comunicam diretamente via namespace de rede, sem passar pelo container firewall. Porém, implementei port forwarding para integrar o firewall no fluxo de forma explícita. Em produção, usaríamos Kubernetes Network Policies ou Service Mesh."

**P: "Como provam que funciona?"**
> "Três evidências: 1) Regras iptables mostram DNAT configurado, 2) Cliente consegue executar queries conectando no IP do firewall, 3) Logs do firewall registram as conexões. Posso demonstrar ao vivo agora."

---

## 🔄 Fluxo de Pacotes Detalhado

### Cliente Envia Query

```
1. Pacote sai do cliente:
   SRC: 10.0.1.60:XXXX
   DST: 10.0.1.20:5432

2. Pacote chega no firewall (PREROUTING):
   DNAT aplicado → DST alterado para 10.0.1.40:5432

3. Pacote passa por FORWARD:
   LOG registra conexão
   ACCEPT permite passagem

4. Pacote sai do firewall (POSTROUTING):
   MASQUERADE aplicado → SRC alterado para 10.0.1.20:YYYY
   
5. Pacote chega no database:
   SRC: 10.0.1.20:YYYY (firewall)
   DST: 10.0.1.40:5432 (database)
   
6. Database processa query

7. Resposta volta:
   SRC: 10.0.1.40:5432
   DST: 10.0.1.20:YYYY
   
8. Firewall consulta conntrack e reverte NAT:
   DST alterado de volta para 10.0.1.60:XXXX
   
9. Pacote volta ao cliente:
   SRC: 10.0.1.20:5432 (como se firewall fosse o database)
   DST: 10.0.1.60:XXXX
```

**Cliente não sabe que passou pelo NAT!** Transparente.

---

## 💡 Vantagens da Implementação

### 1. Integração Real
Firewall não é apenas "decoração" - processa tráfego ativo.

### 2. Auditoria
Todas as conexões ao database são registradas.

### 3. Controle Centralizado
Fácil adicionar regras de bloqueio/throttling depois:
```bash
# Exemplo: Limitar conexões por IP
iptables -A FORWARD -p tcp --dport 5432 -m connlimit --connlimit-above 5 -j REJECT
```

### 4. Transparência
Cliente não precisa saber que há firewall no meio.

### 5. Demonstração Clara
Evidências visuais (logs, contadores) para apresentação.

---

## 🚧 Limitações Aceitas

### Tráfego Inter-Container Direto
```
SMTP → Database (direto, não passa pelo firewall)
LDAP → Database (direto, não passa pelo firewall)
```

**Motivo:** Arquitetura do Docker networking.

**Mitigado por:**
- Port forwarding explícito para demonstração
- Documentação clara da limitação
- Plano para produção (Network Policies, Service Mesh)

---

## 📚 Arquivos Relacionados

- `docker/firewall/setup_forward.sh` - Configuração automática de port forwarding
- `docker/firewall/firewall.sh` - Script de inicialização
- `scripts/test_firewall_forward.sh` - Teste automatizado
- `docs/FIREWALL_DOCKER.md` - Limitações arquiteturais
- `docs/GUIA_TESTE_E2E.md` - Integração no teste completo

---

## 🎓 Comandos Rápidos

```bash
# Ver regras NAT
docker-compose exec firewall iptables -t nat -L -n -v

# Testar conectividade
docker-compose exec cliente bash -c '</dev/tcp/10.0.1.20/5432'

# Executar query via firewall
docker-compose exec cliente psql -h 10.0.1.20 -U app_user -d empresa_db -c "SELECT NOW();"

# Ver logs
docker-compose exec firewall dmesg | grep "FW-DB"

# Monitorar em tempo real
docker-compose exec firewall dmesg -w | grep "FW-DB"

# Ver contadores
docker-compose exec firewall iptables -L FORWARD -n -v

# Teste completo
./scripts/test_firewall_forward.sh
```

---

**Conclusão:** Firewall totalmente integrado no fluxo, com evidências concretas de processamento de tráfego! 🔥
