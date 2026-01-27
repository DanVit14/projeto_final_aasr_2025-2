#!/bin/bash
# Script para verificar por que a fila não está sendo processada

set +e

echo "=========================================="
echo "Verificando Processamento da Fila"
echo "=========================================="
echo ""

# 1. Verificar todos os processos do Postfix
echo "1. Todos os processos do Postfix:"
docker-compose exec smtp ps aux | grep -E "postfix|master|pickup|qmgr|virtual|smtpd" | grep -v grep
echo ""

# 2. Verificar se o processo virtual está rodando
echo "2. Processo virtual especificamente:"
docker-compose exec smtp ps aux | grep "virtual" | grep -v grep || echo "   ✗ Processo virtual NÃO está rodando!"
echo ""

# 3. Verificar e-mails na fila com detalhes
echo "3. E-mails na fila (detalhado):"
docker-compose exec smtp postqueue -p 2>&1
echo ""

# 4. Verificar logs completos recentes
echo "4. Últimas 50 linhas dos logs do Postfix:"
docker-compose exec smtp tail -50 /var/log/mail.log 2>/dev/null
echo ""

# 5. Verificar logs relacionados ao queue ID específico
echo "5. Logs relacionados ao e-mail na fila (C34A861062):"
docker-compose exec smtp tail -100 /var/log/mail.log 2>/dev/null | grep -i "C34A861062\|user1\|empresa.local" | tail -20
echo ""

# 6. Verificar erros nos logs
echo "6. Erros e warnings nos logs:"
docker-compose exec smtp tail -100 /var/log/mail.log 2>/dev/null | grep -iE "error|fail|reject|warning|fatal" | tail -20
echo ""

# 7. Testar resolução LDAP manualmente
echo "7. Testando resolução LDAP manualmente:"
echo "   Domínio:"
docker-compose exec smtp postmap -q empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-domains.cf 2>&1
echo ""
echo "   Usuário:"
docker-compose exec smtp postmap -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

# 8. Verificar se o qmgr está tentando processar
echo "8. Tentando forçar processamento da fila:"
docker-compose exec smtp postqueue -f 2>&1
sleep 3
echo ""
echo "   Verificando fila novamente:"
docker-compose exec smtp postqueue -p 2>&1
echo ""

# 9. Verificar logs após forçar processamento
echo "9. Logs após forçar processamento:"
docker-compose exec smtp tail -20 /var/log/mail.log 2>/dev/null | tail -10
echo ""

# 10. Verificar configuração do virtual_transport e virtual_mailbox_maps
echo "10. Configuração completa de virtual:"
docker-compose exec smtp postconf | grep -E "virtual_" | head -10
echo ""

echo "=========================================="
echo "Verificação concluída!"
echo "=========================================="
