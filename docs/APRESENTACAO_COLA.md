# Cola para Apresentação 📋

Respostas rápidas para perguntas comuns durante a apresentação.

---

## 🎯 Pergunta 1: "O firewall está a filtrar tráfego entre containers?"

### Resposta Curta ✅
> "O container firewall demonstra configuração de iptables com 6 regras ativas. Em Docker, o isolamento entre containers é gerido pela bridge network. O firewall protege o perímetro (host) e implementei múltiplas camadas de segurança: LDAP, ACLs e relay restrictions."

### Se Insistirem
> "Para fazer o firewall interceptar tráfego inter-container seria necessário configurá-lo como gateway (ip_forward, NAT), o que adiciona complexidade significativa. Em produção usa-se Network Policies (Kubernetes) ou Service Mesh (Istio). Documentei as limitações em `FIREWALL_DOCKER.md`."

### Demonstração
```bash
# Mostrar regras iptables funcionando
docker-compose exec firewall iptables -L -n -v
```

**Ver:** `docs/FIREWALL_DOCKER.md` (págs. 1-3)

---

## 🎯 Pergunta 2: "Porque não usaste antivírus?"

### Resposta ✅
> "O ClamAV foi inicialmente implementado mas desativado por decisão técnica fundamentada. O startup do SMTP passava de 135s para 20s (-85%). O projeto mantém múltiplas camadas de defesa: firewall, antispam (SpamAssassin), autenticação LDAP, ACLs e relay restrictions."

### Se Pedirem Mais Detalhes
> "ClamAV carrega 400 MB de assinaturas na RAM, consumindo 800 MB extra e atrasando o startup. Em produção, antivírus moderno está a migrar para EDR nos endpoints, e muitas empresas usam gateways de email externos (Proofpoint, Mimecast). Documentei em `OPCAO_SEM_ANTIVIRUS.md`."

### Reativação (Se Solicitado)
```bash
# 3-4 minutos
sed -i 's/^# content_filter/content_filter/' docker/smtp/main.cf
docker-compose build smtp --no-cache
docker-compose up -d smtp
sleep 120
```

**Ver:** `docs/OPCAO_SEM_ANTIVIRUS.md`

---

## 🎯 Pergunta 3: "Mostra as ACLs a funcionar"

### Demonstração Rápida ✅
```bash
# Executar teste de ACLs
./scripts/test_acls.sh

# Ou entrar no container database
docker-compose exec database bash

# Ver ACLs configuradas
getfacl /tmp/acl_test/financeiro
getfacl /tmp/acl_test/rh
```

### Explicação
> "Criei 4 cenários: Financeiro (restrito ao grupo), RH (acesso seletivo), TI (administradores) e Compartilhado (com masks). Demonstra ACLs de usuário, grupo, máscaras e default ACLs para herança."

**Ver:** `scripts/test_acls.sh` (linhas 47-90)

---

## 🎯 Pergunta 4: "Como funciona o backup do banco?"

### Demonstração ✅
```bash
# Criar backup
./scripts/backup_db.sh

# Ver backups criados
ls -lh backups/

# Restaurar (se solicitado)
./scripts/restore_db.sh backups/backup_YYYYMMDD_HHMMSS.sql.gz

# Verificar
./scripts/test_crud_db.sh
```

### Explicação
> "Script automatizado faz `pg_dump` do PostgreSQL, comprime com gzip e salva com timestamp. Mantém os últimos 7 backups. O restore é igualmente automatizado, descomprime e restaura via `psql`."

**Ver:** `scripts/backup_db.sh` + `scripts/restore_db.sh`

---

## 🎯 Pergunta 5: "Como está configurado o SMTP?"

### Pontos-Chave ✅
- **Postfix** sem chroot (simplifica sockets)
- **Integração LDAP** para contas virtuais
- **Maildir** (1 ficheiro por email)
- **SpamAssassin** (antispam ativo)
- **Relay restrictions** (só rede 10.0.1.0/24)

### Demonstração
```bash
# Ver configuração
docker-compose exec smtp postconf | grep -E "relay|mydestination|virtual"

# Ver emails entregues
docker-compose exec smtp find /var/mail/vhosts/empresa.local/user1/Maildir/new -type f | wc -l

# Enviar email de teste
docker-compose exec smtp sendmail user1@empresa.local <<EOF
Subject: Teste apresentacao
Corpo do email
EOF
```

**Ver:** `docker/smtp/main.cf` (linhas 1-50)

---

## 🎯 Pergunta 6: "Porque não usaste chroot no Postfix?"

### Resposta ✅
> "Inicialmente tinha chroot ativo mas causava erros 'bad command startup'. Postfix em chroot requer copiar libs, configs e sockets para o jail. Em Docker, o container já fornece isolamento equivalente, então desativar chroot simplifica sem comprometer segurança."

### Prova
```bash
# Ver master.cf (coluna 5 = 'n' = sem chroot)
docker-compose exec smtp head -20 /etc/postfix/master.cf
```

**Ver:** `docs/DECISOES_TECNICAS.md` - Problema #6

---

## 🎯 Pergunta 7: "O NTP está sincronizado?"

### Demonstração ✅
```bash
# Ver tracking
docker-compose exec logs-ntp chronyc tracking

# Ver fontes
docker-compose exec logs-ntp chronyc sources
```

### O Que Mostrar
- **Stratum**: 2-3 (bom)
- **Offset**: <100ms (ótimo se <10ms)
- **Fontes**: 15 servidores NTP brasileiros
- **Melhor fonte**: Marcada com `*`

**Ver:** `docs/EVIDENCIAS/output_completo.txt` (linhas 322-402)

---

## 🎯 Pergunta 8: "Adiciona um usuário LDAP ao vivo"

### Demonstração ✅
```bash
# Adicionar user
docker-compose exec ldap samba-tool user create teste123 Senha@123

# Verificar
docker-compose exec ldap samba-tool user list | grep teste123

# Testar SMTP com novo user
docker-compose exec smtp sendmail teste123@empresa.local <<EOF
Subject: Teste
Corpo
EOF
```

**Tempo**: ~30 segundos

---

## 🎯 Pergunta 9: "Cria uma tabela no PostgreSQL ao vivo"

### Demonstração ✅
```bash
docker-compose exec database psql -U app_user -d empresa_db -c "
CREATE TABLE IF NOT EXISTS demo_apresentacao (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    data TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO demo_apresentacao (nome) VALUES 
    ('Teste 1'),
    ('Teste 2');

SELECT * FROM demo_apresentacao;
"
```

**Tempo**: ~15 segundos

---

## 🎯 Pergunta 10: "Explica a topologia de rede"

### Resposta ✅
> "6 containers em rede bridge customizada (10.0.1.0/24). LDAP é o primeiro a iniciar (dependency), depois logs-ntp e firewall, seguidos de SMTP e database que dependem do LDAP. Cliente é o último (testes). Rede isolada do host, portas mapeadas apenas o necessário: 2222 (SSH), 2525 (SMTP), 5432 (DB), 445 (SMB)."

### Demonstração
```bash
# Ver rede
docker network inspect aasr_net

# Ver IPs
docker-compose ps
```

**Ver:** `docs/TOPOLOGIA.md` (diagrama)

---

## 🎯 Pergunta 11: "Demonstra integração real entre serviços" (MATADORA!)

### Resposta ✅
> "Criei um teste end-to-end que simula workflow corporativo completo: usuário autentica no LDAP, envia email via SMTP (validado contra LDAP), email é entregue no Maildir, logs vão para rsyslog centralizado, e sistema registra auditoria no PostgreSQL. Cliente consulta a auditoria no final. **Todos os 6 serviços integrados em um fluxo único**."

### Demonstração AO VIVO (30s) 🔥
```bash
# Executar workflow completo
./scripts/test_end_to_end.sh

# Output mostrará:
# ✓ Autenticação LDAP
# ✓ Email enviado e entregue
# ✓ Logs centralizados
# ✓ Auditoria no PostgreSQL
# ✓ Consulta de auditoria
```

### Fluxo Visual
```
Cliente → LDAP (auth) → SMTP (email) → Maildir (entrega)
            ↓             ↓               ↓
         rsyslog ← logs centralizados
                         ↓
                    PostgreSQL (audit_log)
                         ↓
                    Cliente consulta
```

**Ver:** `docs/TESTE_END_TO_END.md`

**Pontos fortes:**
- Não é teste de "ping" - é workflow REAL
- Rastreabilidade completa (ID único)
- Auditoria no banco de dados
- 6/6 serviços envolvidos

---

## 📚 Documentos de Referência Rápida

### Durante Apresentação
1. **TOPOLOGIA.md** - Diagrama de rede (página 1)
2. **output_completo.txt** - Evidências de testes
3. **FIREWALL_DOCKER.md** - Se perguntarem sobre firewall

### Backup (Se Precisar)
- `DECISOES_TECNICAS.md` - Problemas resolvidos
- `OPCAO_SEM_ANTIVIRUS.md` - Justificativa antivírus
- `INSTRUCOES_FINAIS.md` - Comandos úteis

---

## 🔥 Comandos de Emergência

### Se Algum Serviço Falhar
```bash
# Ver logs
docker-compose logs -f <serviço>

# Restart
docker-compose restart <serviço>

# Rebuild (último recurso)
docker-compose down
docker-compose up -d
```

### Se SMTP Não Responder
```bash
docker-compose exec smtp postfix status
docker-compose exec smtp tail -20 /var/log/mail.log
docker-compose exec smtp ss -tlnp | grep :25
```

### Se Database Não Conectar
```bash
docker-compose exec database pg_isready -U app_user
docker-compose exec database psql -U app_user -d empresa_db -c "SELECT 1;"
```

---

## 🎯 Pergunta 12: "Logs centralizados funcionam?"

### Resposta ✅
> "Sim! rsyslog centralizado funciona - todos os containers enviam logs para logs-ntp via UDP:514. Os logs são organizados por hostname em `/var/log/remote/`. Se houver algum problema, tenho scripts de diagnóstico e correção prontos."

### Demonstração AO VIVO
```bash
# Terminal 1: Monitorar logs
docker-compose exec logs-ntp tail -f /var/log/remote/mail.empresa.local/postfix.log

# Terminal 2: Gerar log
docker-compose exec smtp logger "DEMO_$(date +%s)"

# Log aparecerá no Terminal 1!
```

### Se Logs Não Funcionarem
```bash
# Diagnosticar
./scripts/diagnose_rsyslog.sh

# Corrigir
./scripts/fix_rsyslog.sh
```

**Ver:** `docs/RSYSLOG_CENTRALIZADO.md`

---

## ✅ Checklist Pré-Apresentação

- [ ] Todos os serviços UP: `docker-compose ps`
- [ ] Testes passando: `./scripts/run_test_services.sh`
- [ ] Backup criado: `ls -lh backups/`
- [ ] Logs limpos: `docker-compose logs --tail=10`
- [ ] **rsyslog configurado**: `./scripts/fix_rsyslog.sh`
- [ ] Esta cola aberta em aba separada 😉

---

## 💡 Dicas Gerais

1. **Se não souberes responder**: "Deixa-me verificar nos logs" (ganha tempo)
2. **Se algo falhar**: "Vou demonstrar outro componente enquanto diagnostico"
3. **Confiança**: Tu implementaste tudo, conheces o projeto melhor que ninguém
4. **Honestidade**: "Esta é uma limitação documentada em X.md" é melhor que inventar

---

**Boa sorte! 🚀 Tu consegues!**
