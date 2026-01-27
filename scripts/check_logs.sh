#!/bin/bash
# Script para verificar logs com filtros

set +e

SERVICE="${1:-smtp}"
FILTER="${2:-error}"
LINES="${3:-50}"

echo "=========================================="
echo "Verificando logs - $SERVICE"
echo "=========================================="
echo ""

case "$FILTER" in
    error)
        echo "Últimos erros:"
        docker-compose logs --tail="$LINES" "$SERVICE" 2>&1 | grep -iE "error|fail|fatal|reject" | tail -20
        ;;
    ldap)
        echo "Logs relacionados a LDAP:"
        docker-compose logs --tail="$LINES" "$SERVICE" 2>&1 | grep -iE "ldap|636|389|tls|ssl" | tail -20
        ;;
    smtp)
        echo "Logs relacionados a SMTP:"
        docker-compose logs --tail="$LINES" "$SERVICE" 2>&1 | grep -iE "smtp|smtpd|25|ehlo|mail" | tail -20
        ;;
    virtual)
        echo "Logs relacionados a virtual:"
        docker-compose logs --tail="$LINES" "$SERVICE" 2>&1 | grep -iE "virtual|maildir|deliver" | tail -20
        ;;
    all)
        echo "Todos os logs recentes:"
        docker-compose logs --tail="$LINES" "$SERVICE" 2>&1 | tail -30
        ;;
    *)
        echo "Buscando: $FILTER"
        docker-compose logs --tail="$LINES" "$SERVICE" 2>&1 | grep -iE "$FILTER" | tail -20
        ;;
esac

echo ""
echo "=========================================="
echo "Verificação concluída!"
echo "=========================================="
