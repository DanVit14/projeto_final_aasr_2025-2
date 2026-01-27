#!/bin/bash
# Script para verificar por que o e-mail não foi entregue

set +e

echo "=========================================="
echo "Verificando Entrega de E-mail"
echo "=========================================="
echo ""

# 1. Verificar logs recentes do Postfix
echo "1. Últimas 50 linhas dos logs do Postfix:"
docker-compose exec smtp tail -50 /var/log/mail.log 2>/dev/null | grep -E "(postfix|sendmail|user1|teste)" || echo "   Nenhum log relevante encontrado"
echo ""

# 2. Verificar queue do Postfix
echo "2. E-mails na queue do Postfix:"
docker-compose exec smtp postqueue -p 2>/dev/null || echo "   Queue vazia ou erro ao verificar"
echo ""

# 3. Verificar se o Postfix consegue resolver o destinatário (usa hash gerado do LDAP)
echo "3. Testando resolução do destinatário user1@empresa.local (hash):"
docker-compose exec smtp postmap -q user1@empresa.local hash:/etc/postfix/ldap/virtual-mailbox-maps.hash 2>&1 || echo "   Erro ao consultar hash"
echo ""

# 4. Verificar se o domínio empresa.local está configurado (hash)
echo "4. Testando se domínio empresa.local está configurado (hash):"
docker-compose exec smtp postmap -q empresa.local hash:/etc/postfix/ldap/virtual-mailbox-domains.hash 2>&1 || echo "   Erro ao consultar domínio"
echo ""

# 5. Verificar configuração do virtual_mailbox_base
echo "5. Configuração virtual_mailbox_base:"
docker-compose exec smtp postconf virtual_mailbox_base
echo ""

# 6. Verificar se o Maildir existe e tem permissões corretas
echo "6. Verificando Maildir do user1:"
docker-compose exec smtp ls -la /var/mail/vhosts/empresa.local/user1/ 2>&1 || echo "   Diretório não encontrado"
echo ""

# 7. Verificar processos do Postfix
echo "7. Processos do Postfix:"
docker-compose exec smtp ps aux | grep -E "(postfix|pickup|qmgr|smtpd)" | grep -v grep
echo ""

# 8. Verificar erros recentes
echo "8. Erros recentes nos logs:"
docker-compose exec smtp tail -100 /var/log/mail.log 2>/dev/null | grep -iE "(error|fail|reject|warning)" | tail -20 || echo "   Nenhum erro encontrado"
echo ""

# 9. Verificar configuração de mailbox_command
echo "9. Configuração mailbox_command (Dovecot deliver):"
docker-compose exec smtp postconf mailbox_command
echo ""

# 10. Testar se o Dovecot deliver funciona
echo "10. Testando se Dovecot deliver está acessível:"
docker-compose exec smtp test -x /usr/lib/dovecot/deliver && echo "   ✓ deliver existe e é executável" || echo "   ✗ deliver não encontrado ou não executável"
docker-compose exec smtp ls -la /usr/lib/dovecot/deliver 2>&1
echo ""

echo "=========================================="
echo "Verificação concluída!"
echo "=========================================="
