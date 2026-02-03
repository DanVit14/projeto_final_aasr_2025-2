# LDAP (Samba AD DC)

## 📋 Visão Geral

**Função:** Active Directory Domain Controller  
**IP:** 10.0.1.30  
**Container:** ldap  
**Software:** Samba 4  
**Domínio:** empresa.local

---

## 🔧 Configuração

### Características

- **Samba AD DC** (Active Directory compatível)
- **Kerberos** integrado
- **DNS** integrado
- **Autenticação centralizada** para SMTP

### Portas

| Porta | Serviço |
|-------|---------|
| 389 | LDAP |
| 636 | LDAPS (SSL) |
| 88 | Kerberos |
| 464 | Kerberos Password Change |

### Usuários Padrão

| Usuário | Senha | Função |
|---------|-------|--------|
| Administrator | Admin123! | Admin do domínio |
| user1 | SenhaForte123! | Usuário teste |
| user2 | SenhaForte123! | Usuário teste |
| user3 | SenhaForte123! | Usuário teste |

---

## ✅ Validação

### Verificar Status

```bash
# Container rodando
docker-compose ps ldap

# Samba rodando
docker-compose exec ldap samba-tool testparm
```

### Listar Usuários

```bash
docker-compose exec ldap samba-tool user list
```

### Criar Usuário

```bash
docker-compose exec ldap samba-tool user create user4 SenhaForte123!
```

### Testar Autenticação

```bash
# Do cliente
docker-compose exec cliente ldapsearch -x -H ldap://ldap \
  -D "CN=Administrator,CN=Users,DC=empresa,DC=local" \
  -w "Admin123!" -b "DC=empresa,DC=local"
```

---

## 🔗 Integração com SMTP

O SMTP consulta o LDAP para:

1. **Virtual Mailboxes:** Verificar se destinatário existe
2. **Sender Login Maps:** Validar remetente autorizado
3. **Aliases:** Resolver aliases de email

### Maps LDAP do Postfix

```bash
# Ver caixas de correio
docker-compose exec smtp postmap -q user1@empresa.local \
  hash:/etc/postfix/ldap/virtual-mailbox-maps.hash

# Ver sender login
docker-compose exec smtp postmap -q user1@empresa.local \
  hash:/etc/postfix/ldap/sender-login-maps.hash
```

---

## 🛠️ Troubleshooting

### LDAP Não Responde

```bash
# Ver logs
docker-compose logs ldap

# Reiniciar
docker-compose restart ldap

# Testar porta
docker-compose exec cliente nc -zv ldap 389
```

### Usuário Não Encontrado

```bash
# Listar todos
docker-compose exec ldap samba-tool user list

# Criar se não existir
docker-compose exec ldap samba-tool user create [usuario] [senha]
```

### Senha Expirada

```bash
# Desabilitar expiração
docker-compose exec ldap samba-tool user setexpiry [usuario] --noexpiry
```

---

## 📁 Arquivos Relacionados

- `docker/ldap/Dockerfile`
- `docker/ldap/init.sh` (inicialização do domínio)
- `docker/smtp/main.cf` (integração LDAP-SMTP)
- `docker/smtp/scripts/update_ldap_maps.sh`

---

**LDAP: Fonte centralizada de autenticação e validação de usuários.** ✅
