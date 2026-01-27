#!/bin/bash
# Teste de antispam (SpamAssassin via Amavis) — conforme PLANO_PROJETO.md
# Envia e-mail com conteúdo típico de spam; se Amavis+SpamAssassin estiver ativo,
# a mensagem pode ser marcada (X-Spam-Status) ou descartada conforme política.

set +e

CONTAINER="${1:-smtp}"
TO="${2:-user1@empresa.local}"

# Assunto/corpo típico de spam (usa padrões que o SpamAssassin costuma detectar)
SUBJECT="URGENTE!!! Ganhe muito dinheiro!!!"
BODY="Voce foi contemplado! Clique aqui agora!!! Oferta limitada!!! Viagra barato!!! Milhoes de dolares!!! Heranca de principe nigeriano!!!"

echo "=========================================="
echo "Teste de antispam (SpamAssassin)"
echo "=========================================="
echo "Destinatário: $TO"
echo ""

docker-compose exec -T "$CONTAINER" bash -c "echo -e \"Subject: $SUBJECT\nFrom: teste@exemplo.com\n\n$BODY\" | /usr/sbin/sendmail $TO" 2>&1

echo ""
echo "Próximos passos:"
echo "  1. Se a mensagem chegar ao Maildir, verifique os headers (X-Spam-Status, X-Spam-Score):"
echo "     docker-compose exec smtp sh -c 'ls -t /var/mail/vhosts/empresa.local/user1/Maildir/new/ | head -1 | xargs -I{} cat /var/mail/vhosts/empresa.local/user1/Maildir/new/{} | head -30'"
echo "  2. Logs do Amavis/SpamAssassin:"
echo "     docker-compose logs smtp --tail=80 2>&1 | grep -iE 'amavis|spam|sa-'"
echo "=========================================="
