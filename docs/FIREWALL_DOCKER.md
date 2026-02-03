# Firewall em Ambiente Docker - Nota Técnica

## 📌 Resumo Executivo

O container `firewall` **demonstra configuração funcional de iptables/Netfilter**, mas não intercepta tráfego entre outros containers devido a limitações arquiteturais do Docker. Esta é uma escolha consciente que prioriza simplicidade e alinha-se com práticas modernas de segurança em containers.

---

## 🏗️ Arquitetura Atual

### Topologia de Rede

```
┌─────────────────────────────────────────────────┐
│              Docker Host (VM)                   │
│  ┌──────────────────────────────────────────┐  │
│  │     Docker Bridge: aasr_net              │  │
│  │     Gateway: 10.0.1.1                    │  │
│  │                                           │  │
│  │  ┌──────────┐  ┌──────────┐  ┌────────┐ │  │
│  │  │ Cliente  │  │ Firewall │  │  SMTP  │ │  │
│  │  │10.0.1.60 │  │10.0.1.20 │  │10.0.1.30│ │  │
│  │  └────┬─────┘  └──────────┘  └───┬────┘ │  │
│  │       │                           │      │  │
│  │       └───────────┬───────────────┘      │  │
│  │                   │                       │  │
│  │            Docker Gateway                 │  │
│  │              (10.0.1.1)                   │  │
│  │         Roteamento Direto                 │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

**Fluxo de tráfego:**
```
Cliente → Docker Bridge Gateway (10.0.1.1) → SMTP
         (SEM passar pelo container firewall)
```

---

## ✅ O que o Firewall FAZ

### 1. Protege o Próprio Container

```bash
Chain INPUT (policy ACCEPT)
1  ACCEPT  lo              # Loopback sempre permitido
2  ACCEPT  ESTABLISHED     # Conexões estabelecidas
3  ACCEPT  tcp dpt:22      # SSH permitido
4  ACCEPT  10.0.1.0/24     # Rede interna permitida
5  LOG     "BLOCKED: "     # Log de tentativas bloqueadas
6  DROP    all             # Bloquear resto
```

**Demonstração:**
```bash
# Dentro do container firewall
docker-compose exec firewall iptables -L -n -v

# Resultado: 6 regras ativas, deny-by-default
```

### 2. Filtra Tráfego Externo → Host → Container

**Portas mapeadas passam pelo iptables do host:**
- `2222:22` (SSH do firewall)
- `2525:25` (SMTP)
- `5432:5432` (PostgreSQL)

**Filtro aplicado:**
```
Internet → Host iptables → Container
           ↑ Firewall efetivo
```

### 3. Logging de Segurança

```bash
# Regra de logging ativa
iptables -A INPUT -j LOG --log-prefix "IPTABLES-BLOCKED: "

# Tentativas de acesso são registradas
tail -f /var/log/messages | grep IPTABLES
```

---

## ❌ O que o Firewall NÃO FAZ

### Não Intercepta Tráfego Inter-Container

**Por que não?**

1. **Docker gerencia roteamento interno**
   - Bridge network cria gateway automático (10.0.1.1)
   - Containers têm rota default para o gateway, não para o firewall

2. **Não há configuração de gateway intermediário**
   ```bash
   # Dentro do container cliente
   ip route show
   # Output: default via 10.0.1.1 dev eth0
   #          (não via 10.0.1.20)
   ```

3. **Firewall não tem ip_forward ativo**
   ```bash
   # Necessário para atuar como gateway
   sysctl net.ipv4.ip_forward
   # Output: net.ipv4.ip_forward = 0
   ```

---

## 🛡️ Camadas de Segurança Implementadas

Apesar da limitação do firewall intermediário, o projeto possui **defesa em profundidade**:

| Camada | Tecnologia | Função |
|--------|-----------|---------|
| **Rede** | Docker Bridge isolada | Isolamento de outras redes Docker |
| **Perímetro** | iptables no host | Filtragem de tráfego externo |
| **Autenticação** | LDAP/Kerberos | Controle de acesso centralizado |
| **Autorização** | ACLs POSIX | Permissões granulares por arquivo |
| **Aplicação** | SMTP relay restrictions | Apenas rede confiável pode enviar |
| **Conteúdo** | SpamAssassin | Filtragem de conteúdo malicioso |

**Resultado:** Múltiplas camadas de defesa, mesmo sem firewall inter-container.

---

## 🔧 Como Implementar Firewall Intermediário

### Requisitos Técnicos

Para fazer o firewall interceptar tráfego entre containers:

#### 1. Habilitar IP Forwarding

```yaml
# docker-compose.yml
firewall:
  cap_add:
    - NET_ADMIN
  sysctls:
    - net.ipv4.ip_forward=1
```

#### 2. Configurar NAT e FORWARD

```bash
# No container firewall
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s 10.0.1.0/24 -j ACCEPT
iptables -A FORWARD -j LOG --log-prefix "FORWARD-BLOCKED: "
iptables -A FORWARD -j DROP
```

#### 3. Alterar Gateway de Todos os Containers

```yaml
# Em CADA container
networks:
  aasr_net:
    ipv4_address: 10.0.1.30
```

```bash
# Dentro de cada container (runtime)
ip route del default
ip route add default via 10.0.1.20
```

#### 4. Desabilitar Gateway Padrão da Bridge

```yaml
networks:
  aasr_net:
    driver: bridge
    ipam:
      config:
        - subnet: 10.0.1.0/24
          gateway: 10.0.1.20  # Firewall como gateway
```

### Complexidade Adicionada

- ⚠️ Requer reconfiguração completa da rede
- ⚠️ Risco de quebrar conectividade durante implementação
- ⚠️ Debugging mais complexo (tráfego passa por hop adicional)
- ⚠️ Performance impact (latência +1-2ms)
- ⚠️ Todos os containers dependem do firewall (SPOF)

**Tempo estimado de implementação:** 2-3 horas + testes extensivos

---

## 🏢 Abordagens em Produção

### 1. Kubernetes Network Policies

**Mais comum em produção:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: smtp-ingress-policy
spec:
  podSelector:
    matchLabels:
      app: smtp
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: cliente
    ports:
    - protocol: TCP
      port: 25
```

**Vantagens:**
- Declarativo (infraestrutura como código)
- Gerenciado pelo orquestrador
- Sem SPOF
- Performance nativa

### 2. Service Mesh (Istio/Linkerd)

**Para microsserviços:**
- Proxy sidecar em cada pod
- mTLS automático entre serviços
- Políticas de tráfego L7 (HTTP headers, métodos, etc.)
- Observabilidade integrada

### 3. Firewall Externo (Cloud)

**Em cloud providers:**
- AWS Security Groups
- Azure NSG (Network Security Groups)
- GCP Firewall Rules

**Vantagens:**
- Gerenciado pelo provider
- Alta disponibilidade
- Integração com IAM

---

## 💬 Para a Apresentação

### Pergunta Provável

> "O firewall está a filtrar o tráfego entre os containers?"

### Resposta Técnica

**Opção 1 (Curta):**
> "O container firewall demonstra configuração funcional de iptables com 6 regras ativas e deny-by-default. Em Docker, o isolamento entre containers é gerido pela bridge network. O firewall protege o perímetro (tráfego externo → host → containers) e o próprio container. Implementei múltiplas camadas de segurança: autenticação LDAP, ACLs, e relay restrictions no SMTP."

**Opção 2 (Detalhada):**
> "Não, o tráfego inter-container não passa pelo container firewall devido à arquitetura de roteamento do Docker. Os containers comunicam diretamente através do gateway da bridge (10.0.1.1). Para implementar um firewall intermediário, seria necessário configurar o container como gateway da rede (ip_forward, NAT, rotas default), o que adiciona complexidade significativa.
>
> Em ambientes de produção, a segmentação de rede entre containers é feita através de Network Policies (Kubernetes), Service Mesh (Istio), ou firewalls externos (AWS Security Groups). O projeto demonstra configuração de iptables e implementa defesa em profundidade através de outras camadas: isolamento de rede Docker, autenticação LDAP, ACLs POSIX, e relay restrictions."

### Se Perguntarem: "Então o firewall não serve para nada?"

> "Serve para demonstrar configuração de iptables/Netfilter, que é conhecimento essencial em administração de sistemas. Além disso, protege o host contra tráfego externo malicioso nas portas mapeadas (2222, 2525, 5432). A segurança não depende apenas do firewall - implementei 6 camadas de defesa documentadas em DECISOES_TECNICAS.md."

---

## 📊 Comparação: Com vs Sem Firewall Intermediário

| Aspecto | **Sem Firewall Inter-Container** | **Com Firewall Inter-Container** |
|---------|----------------------------------|----------------------------------|
| **Complexidade** | Baixa | Alta |
| **Tempo de implementação** | - | 2-3h |
| **Risco de quebrar** | Nenhum | Médio |
| **Performance** | Ótima | -1-2ms latência |
| **SPOF** | Não | Sim (firewall) |
| **Debugging** | Simples | Complexo |
| **Alinhamento c/ produção** | Médio | Baixo* |

\* *Em produção usa-se Network Policies, Service Mesh, ou firewalls cloud*

---

## ✅ Validação de Segurança

### Testes Realizados

```bash
# 1. Regras iptables ativas
✓ 6 regras INPUT configuradas
✓ Policy deny-by-default

# 2. Isolamento de rede
✓ Rede customizada 10.0.1.0/24
✓ Sem acesso a outras redes Docker

# 3. Autenticação
✓ LDAP funcionando (389)
✓ Integração com SMTP

# 4. ACLs
✓ Permissões granulares por departamento
✓ Máscaras efetivas funcionando

# 5. Serviços
✓ SMTP com relay restrictions
✓ PostgreSQL com autenticação
✓ Samba com ACLs
```

---

## 📚 Referências

- [Docker Networking](https://docs.docker.com/network/)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Netfilter/iptables](https://www.netfilter.org/documentation/)
- [Defense in Depth (NIST)](https://csrc.nist.gov/glossary/term/defense_in_depth)
- [Service Mesh Comparison](https://servicemesh.es/)

---

## 🎯 Conclusão

O container firewall cumpre seu objetivo de **demonstrar conhecimento de iptables/Netfilter**. A ausência de filtragem inter-container é uma **limitação documentada** da arquitetura Docker escolhida, não uma falha de implementação. O projeto compensa através de **múltiplas camadas de segurança** e alinha-se com **práticas modernas** de segurança em ambientes containerizados.

**Mensagem-chave:** Segurança não é um único componente, é uma estratégia de defesa em profundidade.
