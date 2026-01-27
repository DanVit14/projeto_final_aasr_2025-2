#!/bin/bash
# Script para testar consultas LDAP com ldapsearch

set +e

QUERY="${1:-user1}"
SERVICE="${2:-ldap}"

echo "=========================================="
echo "Testando ldapsearch - $QUERY"
echo "=========================================="
echo ""

case "$QUERY" in
    user1)
        echo "1. Buscando user1 por sAMAccountName:"
        docker-compose exec "$SERVICE" ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(sAMAccountName=user1)" mail sAMAccountName 2>&1
        echo ""
        echo "2. Buscando user1 por mail:"
        docker-compose exec "$SERVICE" ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=user1@empresa.local)" sAMAccountName 2>&1
        ;;
    mail)
        echo "Buscando todos os usuários com atributo mail:"
        docker-compose exec "$SERVICE" ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=*)" mail sAMAccountName 2>&1 | head -30
        ;;
    all)
        echo "Buscando todos os usuários:"
        docker-compose exec "$SERVICE" ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(objectClass=person)" sAMAccountName mail 2>&1 | head -30
        ;;
    filter)
        FILTER="${3:-(objectClass=*)}"
        echo "Buscando com filtro customizado: $FILTER"
        docker-compose exec "$SERVICE" ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "$FILTER" 2>&1 | head -30
        ;;
    *)
        echo "Buscando: $QUERY"
        docker-compose exec "$SERVICE" ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(sAMAccountName=$QUERY)" 2>&1
        ;;
esac

echo ""
echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
