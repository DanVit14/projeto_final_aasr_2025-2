#!/bin/bash
# Teste de antivírus (EICAR) — conforme PLANO_PROJETO.md
# Se Amavis+ClamAV estiver ativo, esta mensagem deve ser detectada e não chegar ao Maildir do destinatário
# (ou o destinatário recebe notificação de vírus; verifique /var/lib/amavis/virusmails)

set +e

CONTAINER="${1:-smtp}"
TO="${2:-user1@empresa.local}"

# String padrão EICAR (arquivo de teste de antivírus — não é vírus real)
EICAR='X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'

echo "=========================================="
echo "Teste EICAR (antivírus)"
echo "=========================================="
echo "Destinatário: $TO"
echo "Se o antivírus (Amavis+ClamAV) estiver ativo, esta mensagem deve ser detectada."
echo ""

docker-compose exec -T "$CONTAINER" bash -c "echo -e \"Subject: Teste EICAR - Antivirus\n\nCorpo do e-mail contendo a string de teste EICAR:\n\n$EICAR\n\nFim.\" | /usr/sbin/sendmail $TO" 2>&1

echo ""
echo "Próximos passos:"
echo "  1. Aguarde ~10 s e verifique se a mensagem NÃO chegou ao Maildir do destinatário:"
echo "     docker-compose exec smtp find /var/mail/vhosts/empresa.local/user1/Maildir -name '*EICAR*' -o -mmin -1 -type f 2>/dev/null | head -5"
echo "  2. Se o antivírus bloqueou, a mensagem pode estar em quarentena:"
echo "     docker-compose exec smtp ls -la /var/lib/amavis/virusmails/ 2>/dev/null"
echo "  3. Logs do Amavis/ClamAV:"
echo "     docker-compose logs smtp --tail=50 2>&1 | grep -iE 'amavis|clamav|eicar|virus'"
echo "=========================================="
