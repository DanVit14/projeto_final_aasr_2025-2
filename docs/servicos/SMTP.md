# SMTP (Postfix + Dovecot)

## 📋 Visão Geral

**Função:** Servidor de email (envio e entrega)  
**IP:** 10.0.1.30  
**Container:** smtp  
**Software:** Postfix + Dovecot + SpamAssassin

---

## 🔧 Configuração

### Componentes

- **Postfix:** MTA (envio/recebimento)
- **Dovecot:** IMAP/POP3 (acesso a caixas)
- **SpamAssassin:** Filtro antispam
- **ClamAV:** Desativado (ver seção abaixo)

### Porta Exposta

| Porta Host | Porta Container | Serviço |
|------------|-----------------|---------|
| 2525 | 25 | SMTP |

### Diretórios

- **Maildir:** `/var/mail/empresa.local/[usuario]/`
- **Configuração:** `/etc/postfix/`
- **LDAP Maps:** `/etc/postfix/ldap/`

---

## 📧 Envio de Email

### Teste Manual

```bash
# Do cliente
docker-compose exec cliente sendmail user1@empresa.local <<EOF
From: admin@empresa.local
To: user1@empresa.local
Subject: Teste

Mensagem de teste.
EOF
```

### Verificar Entrega

```bash
# Ver Maildir
docker-compose exec smtp ls -R /var/mail/empresa.local/user1/

# Deve ter arquivos em new/ ou cur/
```

---

## 🔗 Integração LDAP

### Mapas LDAP

O Postfix consulta LDAP para:

1. **virtual-mailbox-maps:** Usuário tem caixa de correio?
2. **virtual-alias-maps:** Aliases (@todos, @vendas, etc.)
3. **sender-login-maps:** Remetente autorizado?

### Atualizar Mapas

```bash
# Executar no container
docker-compose exec smtp /scripts/update_ldap_maps.sh

# Verifica arquivos gerados
docker-compose exec smtp ls -lh /etc/postfix/ldap/*.hash.db
```

---

## 🛡️ ClamAV/Amavis - Desativados

**Decisão:** Antivírus desativado

**Motivos:**
1. **Startup lento:** 135s → 20s (-85%)
2. **Recurso intensivo:** 800 MB RAM extra
3. **Múltiplas camadas de defesa já existentes:**
   - Firewall
   - SpamAssassin (antispam)
   - Autenticação LDAP
   - ACLs
   - Relay restrictions

**Produção:** EDR nos endpoints, gateway de email externo (Proofpoint, Mimecast)

---

## ✅ Validação

### Postfix Rodando

```bash
docker-compose exec smtp postfix status

# ou
docker-compose exec smtp ps aux | grep postfix
```

### Queue

```bash
# Ver fila
docker-compose exec smtp mailq

# Vazia = "Mail queue is empty"
```

### Logs

```bash
# Logs locais
docker-compose exec smtp tail -f /var/log/mail.log

# Logs do Postfix
docker-compose logs smtp | grep postfix
```

---

## 🛠️ Troubleshooting

### SMTP Não Inicia

**Ver erro:**
```bash
docker-compose logs smtp | tail -50
```

**Erros comuns:**
- `fatal: ... smtpd_relay_restrictions` → Ver `main.cf`
- `bad command startup` → Ver `master.cf`

**Solução:**
```bash
docker-compose restart smtp
```

### Email Não Entrega

**Verificar:**
1. Usuário existe no LDAP?
   ```bash
   docker-compose exec ldap samba-tool user list | grep user1
   ```

2. Maildir criado?
   ```bash
   docker-compose exec smtp ls -ld /var/mail/empresa.local/user1
   ```

3. Mapas LDAP atualizados?
   ```bash
   docker-compose exec smtp /scripts/update_ldap_maps.sh
   ```

4. Logs do Postfix
   ```bash
   docker-compose exec smtp grep "user1" /var/log/mail.log
   ```

### Relay Access Denied

**Erro:**
```
Relay access denied
```

**Causa:** Remetente não autorizado

**Solução:**
```bash
# Atualizar sender-login-maps
docker-compose exec smtp /scripts/update_ldap_maps.sh

# Verificar configuração
docker-compose exec smtp postconf | grep relay_restrictions
```

---

## 📁 Arquivos Relacionados

- `docker/smtp/Dockerfile`
- `docker/smtp/main.cf` (config principal)
- `docker/smtp/master.cf` (serviços)
- `docker/smtp/init.sh` (startup)
- `docker/smtp/scripts/update_ldap_maps.sh`

---

**SMTP: Servidor de email integrado com LDAP e antispam.** ✅
