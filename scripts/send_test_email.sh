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

# Garantir que o Postfix está pronto (pickup/cleanup)
docker-compose exec -T smtp bash -c "for i in 1 2 3 4 5; do /usr/sbin/postfix status >/dev/null 2>&1 && [ -e /var/spool/postfix/public/pickup ] 2>/dev/null && break; sleep 1; done"
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
echo "Se a mensagem ficar na fila e não aparecer no Maildir, use:"
echo "  ./scripts/diagnose_queue_and_delivery.sh   # mostra motivo do defer em mail.log"
echo ""
