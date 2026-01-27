#!/bin/bash
# Script para testar postmap com diferentes consultas LDAP

set +e

EMAIL="${1:-user1@empresa.local}"
MAP_TYPE="${2:-mailbox}"

echo "=========================================="
echo "Testando postmap - $EMAIL"
echo "=========================================="
echo ""

case "$MAP_TYPE" in
    domain)
        echo "Testando domínio virtual:"
        docker-compose exec smtp postmap -q empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-domains.cf 2>&1
        ;;
    mailbox)
        echo "Testando caixa de correio:"
        docker-compose exec smtp postmap -q "$EMAIL" ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
        ;;
    alias)
        echo "Testando alias:"
        docker-compose exec smtp postmap -q "$EMAIL" ldap:/etc/postfix/ldap/ldap-virtual-alias-maps.cf 2>&1
        ;;
    sender)
        echo "Testando sender login:"
        docker-compose exec smtp postmap -q "$EMAIL" ldap:/etc/postfix/ldap/ldap-sender-login-maps.cf 2>&1
        ;;
    all)
        echo "1. Domínio virtual:"
        docker-compose exec smtp postmap -q empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-domains.cf 2>&1
        echo ""
        echo "2. Caixa de correio:"
        docker-compose exec smtp postmap -q "$EMAIL" ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
        echo ""
        echo "3. Alias:"
        docker-compose exec smtp postmap -q "$EMAIL" ldap:/etc/postfix/ldap/ldap-virtual-alias-maps.cf 2>&1
        echo ""
        echo "4. Sender login:"
        docker-compose exec smtp postmap -q "$EMAIL" ldap:/etc/postfix/ldap/ldap-sender-login-maps.cf 2>&1
        ;;
    *)
        echo "Uso: $0 [email] [domain|mailbox|alias|sender|all]"
        echo "Exemplo: $0 user1@empresa.local mailbox"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
