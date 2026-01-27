#!/bin/bash
# Script para debugar entrega de e-mail

set +e

echo "=========================================="
echo "Debug: Entrega de E-mail"
echo "=========================================="
echo ""

# 1. Verificar se o Postfix consegue resolver o destinatário
echo "1. Testando resolução LDAP do destinatário:"
echo "   Testando domínio empresa.local:"
docker-compose exec smtp postmap -q empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-domains.cf 2>&1
echo ""
echo "   Testando user1@empresa.local:"
docker-compose exec smtp postmap -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

# 2. Verificar configuração do virtual_transport
echo "2. Configuração virtual_transport:"
docker-compose exec smtp postconf virtual_transport
echo ""

# 3. Verificar se o serviço virtual está no master.cf
echo "3. Verificando serviço virtual no master.cf:"
docker-compose exec smtp grep "^virtual" /etc/postfix/master.cf
echo ""

# 4. Verificar processos do Postfix
echo "4. Processos do Postfix (especialmente virtual):"
docker-compose exec smtp ps aux | grep -E "(postfix|virtual|qmgr)" | grep -v grep
echo ""

# 5. Verificar logs completos recentes
echo "5. Últimas 100 linhas dos logs do Postfix:"
docker-compose exec smtp tail -100 /var/log/mail.log 2>/dev/null | tail -50
echo ""

# 6. Verificar queue
echo "6. Queue do Postfix:"
docker-compose exec smtp postqueue -p 2>&1
echo ""

# 7. Verificar se o Maildir existe
echo "7. Verificando estrutura do Maildir:"
docker-compose exec smtp ls -laR /var/mail/vhosts/empresa.local/user1/ 2>&1 | head -20
echo ""

# 8. Verificar permissões
echo "8. Verificando permissões do Maildir:"
docker-compose exec smtp ls -ld /var/mail/vhosts/empresa.local/user1/Maildir/ 2>&1
docker-compose exec smtp ls -ld /var/mail/vhosts/empresa.local/user1/Maildir/new/ 2>&1
echo ""

# 9. Verificar configuração do virtual_mailbox_base
echo "9. Configuração virtual_mailbox_base:"
docker-compose exec smtp postconf virtual_mailbox_base
echo ""

# 10. Tentar enviar um e-mail e capturar logs em tempo real
echo "10. Enviando e-mail de teste e monitorando logs:"
docker-compose exec -T smtp bash -c 'echo -e "Subject: Teste Debug\n\nE-mail de teste para debug." | /usr/sbin/sendmail -v user1@empresa.local 2>&1' &
SEND_PID=$!
sleep 3
echo "   Logs após envio:"
docker-compose exec smtp tail -20 /var/log/mail.log 2>/dev/null | grep -E "(user1|empresa.local|virtual|delivered|sent)" || echo "   Nenhum log relevante encontrado"
wait $SEND_PID 2>/dev/null
echo ""

echo "=========================================="
echo "Debug concluído!"
echo "=========================================="
