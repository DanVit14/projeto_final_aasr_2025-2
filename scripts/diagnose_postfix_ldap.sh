#!/bin/bash
# Script para diagnosticar especificamente o problema de conexão LDAP do Postfix

set +e

echo "=========================================="
echo "Diagnóstico Postfix/LDAP - Conexão"
echo "=========================================="
echo ""

# 1. Verificar se o Postfix consegue resolver o hostname
echo "1. Verificando resolução DNS do Postfix:"
docker-compose exec smtp getent hosts ldap 2>&1
echo ""

# 2. Verificar conectividade TCP do Postfix (usando netcat)
echo "2. Testando conectividade TCP (porta 636) do container SMTP:"
docker-compose exec smtp timeout 3 nc -zv ldap 636 2>&1
echo ""

# 3. Verificar se o Postfix está rodando
echo "3. Verificando se o Postfix está rodando:"
docker-compose exec smtp postfix status 2>&1 | head -5
echo ""

# 4. Verificar configuração LDAP dentro do container
echo "4. Verificando configuração LDAP do Postfix:"
docker-compose exec smtp cat /etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

# 5. Testar postmap com debug máximo
echo "5. Testando postmap com debug:"
docker-compose exec smtp postmap -v -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

# 6. Verificar se há bibliotecas LDAP instaladas
echo "6. Verificando bibliotecas LDAP:"
docker-compose exec smtp ldconfig -p | grep ldap 2>&1 | head -10
echo ""

# 7. Testar ldapsearch do container SMTP (mesmo ambiente do Postfix)
echo "7. Testando ldapsearch do container SMTP (mesmo ambiente):"
docker-compose exec smtp ldapsearch -x -H ldaps://ldap:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -o nettimeout=5 -LLL "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -10
echo ""

# 8. Verificar variáveis de ambiente do Postfix
echo "8. Verificando configuração do Postfix relacionada a LDAP:"
docker-compose exec smtp postconf | grep -i ldap 2>&1 | head -10
echo ""

# 9. Verificar logs do Postfix para erros LDAP
echo "9. Logs recentes do Postfix relacionados a LDAP:"
docker-compose logs --tail=50 smtp 2>&1 | grep -iE "ldap|636|error|fail|bind" | tail -15
echo ""

# 10. Testar usando IP direto ao invés de hostname
echo "10. Testando postmap usando IP direto (10.0.1.10):"
# Criar arquivo temporário com IP
docker-compose exec smtp bash -c 'cat > /tmp/test-ldap-ip.cf << EOF
server_host = 10.0.1.10
server_port = 636
version = 3
bind = yes
start_tls = no
tls_require_cert = no
bind_timeout = 10
timeout = 10
bind_dn = cn=Administrator,cn=Users,dc=empresa,dc=local
bind_pw = Admin@123
search_base = dc=empresa,dc=local
query_filter = (&(objectClass=person)(mail=%s))
result_attribute = sAMAccountName
result_format = %d/%s/Maildir/
EOF
postmap -v -q user1@empresa.local ldap:/tmp/test-ldap-ip.cf 2>&1'
echo ""

echo "=========================================="
echo "Diagnóstico concluído!"
echo "=========================================="
