#!/bin/bash
# Diagnóstico de fila e entrega virtual: flush, mail.log e motivo do defer
# Uso: ./scripts/diagnose_queue_and_delivery.sh [container]
# Após rodar, procure no bloco "mail.log (defer/virtual)" por "status=deferred"
# e pela linha seguinte — o motivo exato (Permission denied, No such file, etc.)

set +e

CONTAINER="${1:-smtp}"

echo "=========================================="
echo "Diagnóstico: Fila + Entrega Virtual"
echo "=========================================="
echo ""

echo "0. Postfix está rodando dentro do container?"
if docker-compose exec -T "$CONTAINER" /usr/sbin/postfix status 2>/dev/null; then
    echo "   ✓ Postfix está ativo."
else
    echo "   ✗ Postfix está PARADO ou sockets inacessíveis (public/qmgr, showq)."
    echo "   → Rode: docker-compose logs smtp --tail=80"
    echo "   → Ou:   docker-compose exec smtp /usr/sbin/postfix status"
    echo "   → Se o init derrubar o master após o start, revise docker/smtp/init.sh e os logs do container."
fi
echo ""

echo "1. Fila ANTES do flush:"
docker-compose exec -T "$CONTAINER" postqueue -p 2>&1
echo ""

echo "2. Forçando flush (postqueue -f) e aguardando 8s..."
docker-compose exec -T "$CONTAINER" postqueue -f 2>&1
sleep 8
echo ""

echo "3. Fila APÓS o flush:"
docker-compose exec -T "$CONTAINER" postqueue -p 2>&1
echo ""

echo "4. Arquivos em Maildir (user1):"
docker-compose exec -T "$CONTAINER" find /var/mail/vhosts/empresa.local/user1 -type f 2>&1
echo "   (vazio = mensagens ainda não entregues)"
echo ""

echo "5. mail.log — últimas 120 linhas (procure por status=deferred e pelo motivo):"
docker-compose exec -T "$CONTAINER" tail -120 /var/log/mail.log 2>/dev/null || echo "   /var/log/mail.log não existe (rsyslog pode não estar ativo)"
echo ""

echo "6. mail.log — linhas com defer/relay/status/virtual/qmgr/erro (últimas 200 linhas):"
docker-compose exec -T "$CONTAINER" tail -200 /var/log/mail.log 2>/dev/null | grep -iE "status=|deferred|relay=|to=<|from=<|postfix/qmgr|postfix/virtual|postfix/cleanup|error|warning|Permission denied|No such file|private/rewrite" || echo "   Nenhuma linha de entrega/defer encontrada"
echo ""

echo "6b. Serviço rewrite no master.cf (o cleanup precisa dele; deve listar 'rewrite' ou 'trivial-rewrite'):"
docker-compose exec -T "$CONTAINER" grep -E "^rewrite |^trivial-rewrite " /etc/postfix/master.cf 2>/dev/null || echo "   Serviço rewrite NÃO encontrado no container — rebuild com master.cf que tenha a linha 'rewrite unix ... trivial-rewrite'"
echo ""

echo "7. strict_mailbox_ownership (se yes, diretório deve ser do UID em virtual_uid_maps):"
docker-compose exec -T "$CONTAINER" postconf strict_mailbox_ownership virtual_uid_maps virtual_gid_maps 2>/dev/null
echo ""

echo "8. Caminho virtual para user1@empresa.local + dono do Maildir:"
PATH_Q=$(docker-compose exec -T "$CONTAINER" postmap -q user1@empresa.local hash:/etc/postfix/ldap/virtual-mailbox-maps.hash 2>/dev/null)
BASE=$(docker-compose exec -T "$CONTAINER" postconf -h virtual_mailbox_base 2>/dev/null)
echo "   virtual_mailbox_base = $BASE"
echo "   virtual_mailbox_maps(user1@empresa.local) = $PATH_Q"
echo "   full = $BASE/$PATH_Q"
docker-compose exec -T "$CONTAINER" ls -la /var/mail/vhosts/empresa.local/user1/Maildir/ 2>/dev/null || echo "   (Maildir não encontrado)"
echo ""

echo "=========================================="
echo "Se a fila continuar com itens e não houver arquivos em Maildir,"
echo "use o bloco 5 ou 6 acima: a linha com 'status=deferred' indica o motivo."
echo "=========================================="
