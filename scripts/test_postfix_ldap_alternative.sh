#!/bin/bash
# Script para testar abordagens alternativas para LDAP no Postfix

set +e

echo "=========================================="
echo "Testando Abordagens Alternativas LDAP/Postfix"
echo "=========================================="
echo ""

# 1. Verificar versão do Postfix e postfix-ldap
echo "1. Verificando versões:"
docker-compose exec smtp postconf mail_version 2>&1
docker-compose exec smtp dpkg -l | grep -E "postfix|postfix-ldap" 2>&1
echo ""

# 2. Verificar se há algum problema conhecido com a versão
echo "2. Verificando biblioteca LDAP usada pelo Postfix:"
docker-compose exec smtp ldd /usr/lib/postfix/master 2>&1 | grep ldap || echo "   Nenhuma dependência LDAP encontrada no master"
docker-compose exec smtp find /usr/lib/postfix -name "*ldap*" 2>&1
echo ""

# 3. Testar se o problema é específico do postmap ou geral
echo "3. Testando se outros comandos do Postfix conseguem usar LDAP:"
docker-compose exec smtp postconf -m 2>&1 | grep ldap || echo "   LDAP não listado como método disponível"
echo ""

# 4. Verificar se há alguma configuração de chroot que possa estar bloqueando
echo "4. Verificando configuração de chroot do Postfix:"
docker-compose exec smtp postconf | grep -E "queue_directory|daemon_directory|chroot" 2>&1 | head -5
echo ""

# 5. Tentar usar postmap com strace para ver o que está acontecendo
echo "5. Verificando se há algum problema de permissão ou acesso a arquivos:"
docker-compose exec smtp ls -la /etc/postfix/ldap/ 2>&1
docker-compose exec smtp ls -la /etc/ldap/ldap.conf 2>&1
echo ""

# 6. Verificar se o problema é com a inicialização SSL/TLS
echo "6. Verificando se há bibliotecas SSL disponíveis:"
docker-compose exec smtp ldd /usr/lib/postfix/master 2>&1 | grep -E "ssl|tls|crypto" | head -5
echo ""

# 7. Testar uma consulta LDAP simples usando um script externo
echo "7. Criando script wrapper para testar consulta LDAP:"
docker-compose exec smtp bash -c 'cat > /tmp/test_ldap_wrapper.sh << "EOF"
#!/bin/bash
# Wrapper para consulta LDAP
EMAIL="$1"
RESULT=$(ldapsearch -x -H ldaps://ldap:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(&(objectClass=person)(mail=$EMAIL))" sAMAccountName 2>/dev/null | grep "^sAMAccountName:" | cut -d: -f2 | tr -d " ")
if [ -n "$RESULT" ]; then
    echo "empresa.local/$RESULT/Maildir/"
fi
EOF
chmod +x /tmp/test_ldap_wrapper.sh
/tmp/test_ldap_wrapper.sh user1@empresa.local 2>&1'
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
echo ""
echo "Se o script wrapper funcionar, podemos usar uma abordagem alternativa:"
echo "  - Usar um script externo que faz a consulta LDAP"
echo "  - Ou usar um proxy LDAP local"
echo "  - Ou documentar como limitação conhecida e focar em outras partes"
