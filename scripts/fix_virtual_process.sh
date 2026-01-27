#!/bin/bash
# Script para diagnosticar e corrigir o processo virtual

set +e

echo "=========================================="
echo "Diagnosticando Processo Virtual"
echo "=========================================="
echo ""

# 1. Verificar logs do Docker (já que mail.log não existe)
echo "1. Logs do container SMTP (últimas 50 linhas):"
docker-compose logs --tail=50 smtp 2>&1 | tail -30
echo ""

# 2. Verificar se o Postfix consegue resolver o destinatário
echo "2. Testando resolução LDAP do destinatário:"
echo "   Domínio empresa.local:"
docker-compose exec smtp postmap -q empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-domains.cf 2>&1
echo ""
echo "   Usuário user1@empresa.local:"
docker-compose exec smtp postmap -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

# 3. Verificar configuração do virtual_transport
echo "3. Configuração virtual_transport:"
docker-compose exec smtp postconf virtual_transport virtual_mailbox_maps virtual_mailbox_domains
echo ""

# 4. Verificar se o serviço virtual está no master.cf
echo "4. Serviço virtual no master.cf:"
docker-compose exec smtp grep "^virtual" /etc/postfix/master.cf
echo ""

# 5. Tentar forçar o Postfix a recarregar e iniciar o virtual
echo "5. Recarregando Postfix para iniciar processos:"
docker-compose exec smtp postfix reload 2>&1
sleep 3
echo ""

# 6. Verificar processos novamente
echo "6. Processos do Postfix após reload:"
docker-compose exec smtp ps aux | grep -E "postfix|master|pickup|qmgr|virtual" | grep -v grep
echo ""

# 7. Tentar processar a fila manualmente
echo "7. Tentando processar fila manualmente:"
docker-compose exec smtp postqueue -f 2>&1
sleep 3
echo ""

# 8. Verificar se o virtual iniciou após processar fila
echo "8. Processos após processar fila:"
docker-compose exec smtp ps aux | grep -E "virtual" | grep -v grep || echo "   ✗ Processo virtual ainda NÃO está rodando"
echo ""

# 9. Verificar fila novamente
echo "9. Status da fila:"
docker-compose exec smtp postqueue -p 2>&1
echo ""

# 10. Verificar logs do Docker após processar
echo "10. Logs do Docker após processar fila:"
docker-compose logs --tail=20 smtp 2>&1 | tail -10
echo ""

echo "=========================================="
echo "Diagnóstico concluído!"
echo "=========================================="
