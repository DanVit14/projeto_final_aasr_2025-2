#!/bin/bash
# Script para enviar e-mail de teste

set +e

TO="${1:-user1@empresa.local}"
SUBJECT="${2:-Teste de E-mail}"
BODY="${3:-Este é um e-mail de teste do Postfix.}"

echo "=========================================="
echo "Enviando e-mail de teste"
echo "=========================================="
echo "Para: $TO"
echo "Assunto: $SUBJECT"
echo ""

docker-compose exec -T smtp bash -c "echo -e \"Subject: $SUBJECT\n\n$BODY\" | /usr/sbin/sendmail -v $TO 2>&1"

echo ""
echo "=========================================="
echo "E-mail enviado!"
echo "=========================================="
echo ""
echo "Para verificar se foi entregue:"
echo "  ./scripts/check_email_delivery.sh"
echo "  ./scripts/check_email_logs.sh"
echo ""
