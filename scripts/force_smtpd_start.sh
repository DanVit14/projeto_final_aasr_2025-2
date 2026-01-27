#!/bin/bash
# Script para forçar o smtpd a iniciar e ver o erro

set +e

echo "=========================================="
echo "Forçando smtpd a iniciar"
echo "=========================================="
echo ""

# 1. Parar Postfix completamente
echo "1. Parando Postfix..."
docker-compose exec smtp postfix stop 2>&1
sleep 2

# 2. Verificar se parou
echo "2. Verificando se parou:"
docker-compose exec smtp ps aux | grep postfix | grep -v grep || echo "   Postfix parou"
echo ""

# 3. Limpar arquivos de PID
echo "3. Limpando arquivos de PID:"
docker-compose exec smtp rm -f /var/spool/postfix/pid/*.pid 2>&1
echo ""

# 4. Verificar configuração
echo "4. Verificando configuração:"
docker-compose exec smtp postfix check 2>&1 | head -10
echo ""

# 5. Tentar iniciar com verbose
echo "5. Iniciando Postfix com verbose:"
docker-compose exec smtp postfix start 2>&1
sleep 3

# 6. Verificar status
echo "6. Status do Postfix:"
docker-compose exec smtp postfix status 2>&1
echo ""

# 7. Ver processos
echo "7. Processos Postfix:"
docker-compose exec smtp ps aux | grep -E "postfix|smtpd|master" | grep -v grep
echo ""

# 8. Tentar iniciar smtpd manualmente via master
echo "8. Tentando iniciar smtpd manualmente:"
docker-compose exec smtp bash -c "postfix reload 2>&1; sleep 2; postfix status 2>&1"
echo ""

# 9. Ver logs do syslog se disponível
echo "9. Verificando syslog:"
docker-compose exec smtp tail -20 /var/log/syslog 2>/dev/null | grep -i postfix || echo "   syslog não disponível ou sem logs do Postfix"
echo ""

# 10. Verificar se há problemas com LDAP que impedem smtpd
echo "10. Testando consultas LDAP do Postfix:"
docker-compose exec smtp postmap -q empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-domains.cf 2>&1 | head -3
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
