#!/bin/bash
# Script para testar comandos samba-tool

set +e

COMMAND="${1:-list}"

echo "=========================================="
echo "Testando samba-tool - $COMMAND"
echo "=========================================="
echo ""

case "$COMMAND" in
    users)
        echo "Listando usuários:"
        docker-compose exec ldap samba-tool user list 2>&1
        ;;
    groups)
        echo "Listando grupos:"
        docker-compose exec ldap samba-tool group list 2>&1
        ;;
    domain)
        echo "Informações do domínio:"
        docker-compose exec ldap samba-tool domain info localhost 2>&1 | head -20
        ;;
    user1)
        echo "Informações do user1:"
        docker-compose exec ldap samba-tool user show user1 2>&1
        ;;
    admin)
        echo "Informações do admin:"
        docker-compose exec ldap samba-tool user show admin 2>&1
        ;;
    password)
        USER="${2:-user1}"
        echo "Verificando política de senha para $USER:"
        docker-compose exec ldap samba-tool user passwordsettings show "$USER" 2>&1 | head -10
        ;;
    *)
        echo "Uso: $0 [users|groups|domain|user1|admin|password]"
        echo "Exemplo: $0 users"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
