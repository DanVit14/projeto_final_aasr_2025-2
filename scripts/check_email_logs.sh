#!/bin/bash
# Script para verificar logs detalhados de entrega de e-mail

set +e

echo "=========================================="
echo "Verificando Logs de Entrega de E-mail"
echo "=========================================="
echo ""

# 1. Verificar logs recentes do Postfix
echo "1. Últimas 50 linhas dos logs do Postfix:"
docker-compose exec smtp tail -50 /var/log/mail.log 2>/dev/null | tail -30
echo ""

# 2. Verificar se há e-mails na fila
echo "2. E-mails na fila do Postfix:"
docker-compose exec smtp postqueue -p 2>&1
echo ""

# 3. Verificar logs relacionados a user1@empresa.local
echo "3. Logs relacionados a user1@empresa.local:"
docker-compose exec smtp tail -100 /var/log/mail.log 2>/dev/null | grep -i "user1\|empresa.local" | tail -20
echo ""

# 4. Verificar logs de entrega virtual
echo "4. Logs de entrega virtual:"
docker-compose exec smtp tail -100 /var/log/mail.log 2>/dev/null | grep -iE "virtual|deliver|maildir" | tail -20
echo ""

# 5. Verificar erros recentes
echo "5. Erros recentes nos logs:"
docker-compose exec smtp tail -100 /var/log/mail.log 2>/dev/null | grep -iE "error|fail|reject|warning" | tail -20
echo ""

# 6. Verificar se o processo virtual está rodando
echo "6. Processo virtual do Postfix:"
docker-compose exec smtp ps aux | grep -E "virtual|qmgr" | grep -v grep
echo ""

# 7. Testar resolução LDAP novamente
echo "7. Testando resolução LDAP:"
echo "   Domínio:"
docker-compose exec smtp postmap -q empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-domains.cf 2>&1
echo "   Usuário:"
docker-compose exec smtp postmap -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

# 8. Verificar configuração do virtual_transport
echo "8. Configuração virtual_transport e virtual_mailbox_base:"
docker-compose exec smtp postconf virtual_transport virtual_mailbox_base
echo ""

# 9. Verificar se o Maildir existe e tem permissões corretas
echo "9. Verificando Maildir:"
docker-compose exec smtp ls -ld /var/mail/vhosts/empresa.local/user1/Maildir/ 2>&1
docker-compose exec smtp ls -la /var/mail/vhosts/empresa.local/user1/Maildir/new/ 2>&1 | head -5
echo ""

# 10. Tentar processar a fila manualmente
echo "10. Tentando processar fila manualmente:"
docker-compose exec smtp postqueue -f 2>&1
sleep 2
docker-compose exec smtp postqueue -p 2>&1
echo ""

echo "=========================================="
echo "Verificação concluída!"
echo "=========================================="
