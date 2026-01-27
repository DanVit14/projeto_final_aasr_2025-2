#!/bin/bash
# Script para testar se o Postfix consegue consultar o LDAP

set +e

echo "=========================================="
echo "Testando integração Postfix + LDAP"
echo "=========================================="
echo ""

# Teste 1: Verificar se o Postfix consegue consultar domínios virtuais
echo "1. Testando consulta de domínios virtuais via LDAP..."
DOMAIN_TEST=$(docker-compose exec -T smtp postmap -q empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-domains.cf 2>&1)
if [ -n "$DOMAIN_TEST" ]; then
    echo -e "\033[0;32m✓ OK\033[0m"
    echo "   Postfix consegue consultar LDAP para domínios"
    echo "   Resultado: $DOMAIN_TEST"
else
    echo -e "\033[1;33m⚠ Sem resultado\033[0m"
    echo "   Pode ser normal se não houver usuários com e-mail configurado"
fi
echo ""

# Teste 2: Verificar se o Postfix consegue consultar caixas de correio
echo "2. Testando consulta de caixas de correio via LDAP..."
MAILBOX_TEST=$(docker-compose exec -T smtp postmap -q admin@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1)
if [ -n "$MAILBOX_TEST" ]; then
    echo -e "\033[0;32m✓ OK\033[0m"
    echo "   Postfix consegue consultar LDAP para caixas de correio"
    echo "   Resultado: $MAILBOX_TEST"
else
    echo -e "\033[1;33m⚠ Sem resultado\033[0m"
    echo "   Verifique se os usuários têm atributo 'mail' no LDAP"
    echo "   Execute: docker-compose exec ldap /usr/local/bin/add_email_attributes.sh"
fi
echo ""

# Teste 3: Verificar se o Postfix está escutando
echo "3. Verificando se o Postfix está escutando na porta 25..."
if docker-compose exec -T smtp which nc >/dev/null 2>&1; then
    SMTP_TEST=$(echo "QUIT" | docker-compose exec -T smtp nc localhost 25 2>&1 | head -1)
elif docker-compose exec -T smtp which telnet >/dev/null 2>&1; then
    SMTP_TEST=$(echo "QUIT" | timeout 2 docker-compose exec -T smtp telnet localhost 25 2>&1 | head -1)
else
    SMTP_TEST=$(docker-compose exec -T smtp bash -c 'echo "QUIT" | timeout 2 bash -c "exec 3<>/dev/tcp/localhost/25 && cat <&3 && exec 3<&-"' 2>&1 | head -1)
fi

if echo "$SMTP_TEST" | grep -q "220"; then
    echo -e "\033[0;32m✓ OK\033[0m"
    echo "   Postfix está respondendo: $SMTP_TEST"
else
    echo -e "\033[1;31m✗ FALHOU\033[0m"
    echo "   Postfix não está respondendo corretamente"
    echo "   Detalhes: $SMTP_TEST"
fi
echo ""

# Teste 4: Verificar logs do Postfix para erros LDAP
echo "4. Verificando erros LDAP nos logs do Postfix..."
LDAP_ERRORS=$(docker-compose logs smtp 2>&1 | grep -i "ldap.*error\|ldap.*fail\|can't.*ldap" | tail -5)
if [ -z "$LDAP_ERRORS" ]; then
    echo -e "\033[0;32m✓ OK\033[0m"
    echo "   Nenhum erro LDAP encontrado nos logs recentes"
else
    echo -e "\033[1;33m⚠ Erros encontrados\033[0m"
    echo "$LDAP_ERRORS" | sed 's/^/   /'
fi
echo ""

echo "=========================================="
echo "Testes concluídos!"
echo "=========================================="
echo ""
echo "Para testar envio de e-mail:"
echo "  docker-compose exec smtp mail -s 'Teste' user1@empresa.local < /dev/null"
