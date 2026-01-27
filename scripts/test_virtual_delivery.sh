#!/bin/bash
# Script para testar entrega virtual do Postfix

set +e

echo "=========================================="
echo "Testando Entrega Virtual do Postfix"
echo "=========================================="
echo ""

# 1. Verificar se o processo virtual está rodando
echo "1. Processo virtual do Postfix:"
docker-compose exec smtp ps aux | grep -E "virtual|qmgr" | grep -v grep || echo "   Nenhum processo virtual encontrado"
echo ""

# 2. Verificar se o serviço virtual está no master.cf
echo "2. Serviço virtual no master.cf:"
docker-compose exec smtp grep "^virtual" /etc/postfix/master.cf
echo ""

# 3. Verificar configuração do virtual_transport
echo "3. Configuração virtual_transport:"
docker-compose exec smtp postconf virtual_transport virtual_mailbox_base virtual_mailbox_maps
echo ""

# 4. Testar resolução LDAP do destinatário
echo "4. Testando resolução LDAP:"
echo "   Domínio empresa.local:"
docker-compose exec smtp postmap -q empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-domains.cf 2>&1
echo ""
echo "   Usuário user1@empresa.local:"
docker-compose exec smtp postmap -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

# 5. Verificar logs recentes do Postfix
echo "5. Últimas 30 linhas dos logs do Postfix:"
docker-compose exec smtp tail -30 /var/log/mail.log 2>/dev/null | tail -20
echo ""

# 6. Verificar se há e-mails na fila
echo "6. E-mails na fila:"
docker-compose exec smtp postqueue -p 2>&1 | head -10
echo ""

# 7. Verificar permissões do Maildir
echo "7. Permissões do Maildir:"
docker-compose exec smtp ls -ld /var/mail/vhosts/empresa.local/user1/Maildir/ 2>&1
docker-compose exec smtp ls -ld /var/mail/vhosts/empresa.local/user1/Maildir/new/ 2>&1
echo ""

# 8. Verificar se o Postfix consegue escrever no Maildir
echo "8. Testando escrita no Maildir:"
docker-compose exec smtp bash -c "touch /var/mail/vhosts/empresa.local/user1/Maildir/new/teste 2>&1 && echo '   ✓ Escrita OK' || echo '   ✗ Erro ao escrever'"
docker-compose exec smtp rm -f /var/mail/vhosts/empresa.local/user1/Maildir/new/teste 2>&1
echo ""

# 9. Verificar configuração do virtual_uid_maps e virtual_gid_maps
echo "9. Configuração de UID/GID virtual:"
docker-compose exec smtp postconf virtual_uid_maps virtual_gid_maps virtual_minimum_uid
echo ""

# 10. Verificar se o usuário postfix existe e qual seu UID
echo "10. Informações do usuário postfix:"
docker-compose exec smtp id postfix 2>&1
docker-compose exec smtp getent passwd postfix 2>&1
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
