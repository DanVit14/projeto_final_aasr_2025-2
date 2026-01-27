#!/bin/bash
# Script para testar postconf com diferentes filtros

set +e

FILTER="${1:-all}"

echo "=========================================="
echo "Testando postconf - $FILTER"
echo "=========================================="
echo ""

case "$FILTER" in
    ldap)
        echo "Configurações LDAP:"
        docker-compose exec smtp postconf | grep -iE "ldap|virtual" | head -20
        ;;
    virtual)
        echo "Configurações virtual:"
        docker-compose exec smtp postconf | grep -E "virtual_" | head -20
        ;;
    transport)
        echo "Configurações de transporte:"
        docker-compose exec smtp postconf | grep -E "transport|delivery" | head -20
        ;;
    network)
        echo "Configurações de rede:"
        docker-compose exec smtp postconf | grep -E "inet_|mydestination|mynetworks" | head -20
        ;;
    all)
        echo "Todas as configurações:"
        docker-compose exec smtp postconf 2>&1 | head -50
        ;;
    *)
        echo "Buscando: $FILTER"
        docker-compose exec smtp postconf | grep -iE "$FILTER" | head -20
        ;;
esac

echo ""
echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
