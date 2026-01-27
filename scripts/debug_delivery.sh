#!/bin/bash
# Diagnóstico: por que o e-mail fica na fila e não é entregue

set +e

echo "=========================================="
echo "Diagnóstico de entrega de e-mail"
echo "=========================================="
echo ""

CONTAINER="${1:-smtp}"

echo "1. Resolução virtual_mailbox_maps para user1@empresa.local:"
docker-compose exec -T "$CONTAINER" postmap -q user1@empresa.local hash:/etc/postfix/ldap/virtual-mailbox-maps.hash 2>&1
echo ""

echo "2. Caminho completo (virtual_mailbox_base + resolução):"
base=$(docker-compose exec -T "$CONTAINER" postconf -h virtual_mailbox_base 2>/dev/null)
path=$(docker-compose exec -T "$CONTAINER" postmap -q user1@empresa.local hash:/etc/postfix/ldap/virtual-mailbox-maps.hash 2>/dev/null)
echo "   Base: $base"
echo "   Path: $path"
echo "   Full: ${base}/${path}"
echo ""

echo "3. UID/GID da entrega virtual:"
docker-compose exec -T "$CONTAINER" postconf virtual_uid_maps virtual_gid_maps 2>/dev/null
echo ""

echo "4. Teste de escrita (postfix escrevendo no Maildir):"
docker-compose exec -T "$CONTAINER" su -s /bin/sh postfix -c "touch /var/mail/vhosts/empresa.local/user1/Maildir/new/.test_write 2>&1 && echo '   OK: postfix pode escrever' && rm -f /var/mail/vhosts/empresa.local/user1/Maildir/new/.test_write" || echo "   FALHA: postfix não consegue escrever"
echo ""

echo "5. Diretórios Maildir (new, cur, tmp) existem?"
docker-compose exec -T "$CONTAINER" ls -la /var/mail/vhosts/empresa.local/user1/Maildir/ 2>&1
echo ""

echo "6. Forçando flush e aguardando 5s..."
docker-compose exec -T "$CONTAINER" postqueue -f 2>&1
sleep 5
echo ""

echo "7. Fila após flush:"
docker-compose exec -T "$CONTAINER" postqueue -p 2>&1
echo ""

echo "8. Últimas linhas do container (possível erro de entrega):"
docker-compose logs "$CONTAINER" --tail=80 2>&1 | grep -iE "postfix|virtual|user1|defer|error|warning|delivery|status=" || echo "   (nenhum filtro encontrado - mostrando últimas 30 linhas)"
docker-compose logs "$CONTAINER" --tail=30 2>&1
echo ""

echo "=========================================="
echo "Diagnóstico concluído."
echo "=========================================="
