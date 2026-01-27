#!/bin/bash
# Script para testar o serviço SMTP + Antivírus

set +e

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Testando SMTP + Antivírus"
echo "=========================================="
echo ""

# Teste 1: Verificar se o container está rodando
echo "1. Verificando se o container SMTP está rodando..."
if docker-compose ps smtp | grep -q "Up"; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Container SMTP está rodando"
else
    echo -e "${RED}✗ FALHOU${NC}"
    echo "   Container SMTP não está rodando"
    exit 1
fi
echo ""
sleep 3

# Teste 2: Verificar portas abertas
echo "2. Verificando portas SMTP (25, 587)..."
PORTS=$(docker-compose exec -T smtp netstat -tlnp 2>/dev/null | grep -E ":(25|587)" || docker-compose exec -T smtp ss -tlnp 2>/dev/null | grep -E ":(25|587)")
if [ -n "$PORTS" ]; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "$PORTS" | sed 's/^/   /'
else
    echo -e "${YELLOW}⚠ Verificar manualmente${NC}"
    echo "   Postfix pode estar iniciando..."
fi
echo ""
sleep 3

# Teste 3: Verificar conexão LDAP (LDAPS)
echo "3. Testando conexão LDAP (LDAPS) do SMTP..."
LDAP_TEST=$(docker-compose exec -T smtp ldapsearch -x -H ldaps://ldap:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" 2>&1 | head -5)
if echo "$LDAP_TEST" | grep -qi "dn:"; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Conexão LDAPS funcionando"
else
    echo -e "${YELLOW}⚠ Verificar${NC}"
    echo "   Detalhes: $(echo "$LDAP_TEST" | grep -i "error\\|certificate" | head -1)"
fi
echo ""
sleep 3

# Teste 4: Verificar se usuários têm atributo mail
echo "4. Verificando atributos de e-mail dos usuários..."
USERS_MAIL=$(docker-compose exec -T ldap ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" "(objectClass=person)" mail 2>&1 | grep -i "mail:" | head -5)
if [ -n "$USERS_MAIL" ]; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "$USERS_MAIL" | sed 's/^/   /'
else
    echo -e "${YELLOW}⚠ Nenhum atributo mail encontrado${NC}"
    echo "   Execute: docker-compose exec ldap /usr/local/bin/add_email_attributes.sh"
fi
echo ""
sleep 3

# Teste 5: Testar envio de e-mail local (telnet)
echo "5. Testando envio de e-mail via SMTP (porta 25)..."
SMTP_TEST=$(echo -e "EHLO test.local\nQUIT" | docker-compose exec -T smtp nc localhost 25 2>&1 | head -5)
if echo "$SMTP_TEST" | grep -qi "250"; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Servidor SMTP respondendo"
    echo "$SMTP_TEST" | grep "250" | head -2 | sed 's/^/   /'
else
    echo -e "${YELLOW}⚠ Verificar${NC}"
    echo "   Detalhes: $(echo "$SMTP_TEST" | head -2)"
fi
echo ""
sleep 3

# Teste 6: Verificar ClamAV
echo "6. Verificando ClamAV..."
CLAMAV_TEST=$(docker-compose exec -T smtp pgrep -x clamd 2>/dev/null)
if [ -n "$CLAMAV_TEST" ]; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   ClamAV daemon está rodando (PID: $CLAMAV_TEST)"
else
    echo -e "${YELLOW}⚠ ClamAV pode não estar rodando${NC}"
    echo "   Verificar logs: docker-compose logs smtp | grep -i clam"
fi
echo ""
sleep 3

# Teste 7: Verificar Dovecot
echo "7. Verificando Dovecot..."
DOVECOT_TEST=$(docker-compose exec -T smtp pgrep -x dovecot 2>/dev/null)
if [ -n "$DOVECOT_TEST" ]; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Dovecot está rodando (PID: $DOVECOT_TEST)"
else
    echo -e "${YELLOW}⚠ Dovecot pode não estar rodando${NC}"
    echo "   Verificar logs: docker-compose logs smtp | grep -i dovecot"
fi
echo ""
sleep 3

# Teste 8: Verificar Amavis
echo "8. Verificando Amavis..."
AMAVIS_TEST=$(docker-compose exec -T smtp pgrep -f amavisd 2>/dev/null)
if [ -n "$AMAVIS_TEST" ]; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Amavis está rodando (PID: $AMAVIS_TEST)"
else
    echo -e "${YELLOW}⚠ Amavis pode não estar rodando${NC}"
    echo "   Verificar logs: docker-compose logs smtp | grep -i amavis"
fi
echo ""
sleep 3

# Teste 9: Verificar logs de erro do Postfix
echo "9. Verificando erros recentes no Postfix..."
RECENT_ERRORS=$(docker-compose logs --tail=20 smtp 2>&1 | grep -i "error\\|fatal\\|failed" | tail -5)
if [ -z "$RECENT_ERRORS" ]; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Nenhum erro recente encontrado"
else
    echo -e "${YELLOW}⚠ Erros encontrados${NC}"
    echo "$RECENT_ERRORS" | sed 's/^/   /'
fi
echo ""

echo "=========================================="
echo "Testes concluídos!"
echo "=========================================="
echo ""
echo "Para ver logs detalhados:"
echo "  docker-compose logs -f smtp"
echo ""
echo "Para testar envio de e-mail manualmente:"
echo "  docker-compose exec smtp mail -s 'Teste' user1@empresa.local < /dev/null"
