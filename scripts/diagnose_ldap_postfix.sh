#!/bin/bash
# Script completo para diagnosticar problema de LDAP no Postfix

set +e

echo "=========================================="
echo "Diagnóstico Completo LDAP/Postfix"
echo "=========================================="
echo ""

# 1. Verificar conectividade básica
echo "1. Testando conectividade de rede:"
echo "   Testando porta 636 (LDAPS):"
docker-compose exec smtp timeout 3 nc -zv ldap 636 2>&1
echo ""
echo "   Testando porta 389 (LDAP):"
docker-compose exec smtp timeout 3 nc -zv ldap 389 2>&1
echo ""

# 2. Verificar resolução de DNS
echo "2. Verificando resolução de DNS:"
docker-compose exec smtp getent hosts ldap 2>&1 || docker-compose exec smtp nslookup ldap 2>&1 || echo "   Erro ao resolver"
echo ""

# 3. Verificar configuração dentro do container
echo "3. Verificando configuração LDAP dentro do container:"
echo "   Arquivo ldap-virtual-mailbox-maps.cf:"
docker-compose exec smtp cat /etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

# 4. Testar ldapsearch direto do container SMTP
echo "4. Testando ldapsearch do container SMTP:"
echo "   Tentando LDAPS (porta 636):"
docker-compose exec smtp ldapsearch -x -H ldaps://ldap:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -10
echo ""

# 5. Verificar se o certificado CA está presente
echo "5. Verificando certificados CA:"
docker-compose exec smtp ls -la /etc/ssl/certs/ca-certificates.crt 2>&1
echo "   Verificando se há certificados CA:"
docker-compose exec smtp ls -la /etc/ssl/certs/ | grep -i ca | head -5
echo ""

# 6. Testar postmap com debug
echo "6. Testando postmap com debug:"
docker-compose exec smtp postmap -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

# 7. Verificar se o LDAP está realmente escutando
echo "7. Verificando se o LDAP está escutando:"
docker-compose exec ldap netstat -tlnp 2>/dev/null | grep -E ":(636|389)" || \
docker-compose exec ldap ss -tlnp 2>/dev/null | grep -E ":(636|389)" || \
docker-compose exec ldap lsof -i :636 -i :389 2>/dev/null || \
echo "   Ferramentas não disponíveis"
echo ""

# 8. Testar do container LDAP para si mesmo
echo "8. Testando LDAP do próprio container LDAP:"
docker-compose exec ldap ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -5
echo ""

# 9. Verificar logs recentes
echo "9. Logs recentes do SMTP relacionados a LDAP:"
docker-compose logs --tail=50 smtp 2>&1 | grep -iE "ldap|636|389|tls|ssl|error|fail" | tail -15
echo ""

echo "=========================================="
echo "Diagnóstico concluído!"
echo "=========================================="
