#!/bin/bash
# Script para executar update-ldap-maps.sh no container SMTP
# Use este script quando o container SMTP estiver rodando

set +e

echo "=========================================="
echo "Atualizando Arquivos Hash LDAP"
echo "=========================================="
echo ""

# Verificar se o container está rodando
if ! docker-compose ps smtp | grep -q "Up"; then
    echo "✗ Container SMTP não está rodando!"
    echo ""
    echo "Execute primeiro:"
    echo "  docker-compose up -d smtp"
    echo "  sleep 15"
    echo ""
    exit 1
fi

echo "Executando update-ldap-maps.sh no container SMTP..."
echo ""
docker-compose exec smtp /usr/local/bin/update-ldap-maps.sh 2>&1

echo ""
echo "Recarregando Postfix para aplicar mudanças..."
docker-compose exec smtp postfix reload 2>&1

echo ""
echo "=========================================="
echo "Atualização concluída!"
echo "=========================================="
