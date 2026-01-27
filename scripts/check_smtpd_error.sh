#!/bin/bash
# Script para verificar por que o smtpd não está iniciando

set +e

echo "=========================================="
echo "Diagnosticando problema do smtpd"
echo "=========================================="
echo ""

# 1. Ver logs do Postfix
echo "1. Logs do Postfix (últimas 30 linhas):"
docker-compose logs --tail=30 smtp 2>&1 | grep -iE "smtpd|error|fatal|fail|bind|25" || echo "   Nenhum log relevante encontrado"
echo ""

# 2. Verificar se há arquivo de log do Postfix
echo "2. Verificando logs do sistema:"
docker-compose exec smtp ls -la /var/log/mail.log /var/log/mail.err 2>/dev/null || echo "   Arquivos de log não encontrados"
echo ""

# 3. Tentar iniciar smtpd manualmente e ver o erro
echo "3. Tentando iniciar Postfix e capturar erros:"
docker-compose exec smtp bash -c "postfix stop 2>&1; sleep 1; postfix start 2>&1" | head -20
echo ""

# 4. Verificar configuração do master.cf
echo "4. Verificando master.cf:"
docker-compose exec smtp cat /etc/postfix/master.cf | grep -E "^smtp|^#.*smtp" | head -5
echo ""

# 5. Verificar se há problemas com a porta 25
echo "5. Verificando se a porta 25 está em uso:"
docker-compose exec smtp bash -c "lsof -i :25 2>/dev/null || fuser 25/tcp 2>/dev/null || echo '   lsof/fuser não disponível'"
echo ""

# 6. Verificar permissões
echo "6. Verificando permissões dos diretórios:"
docker-compose exec smtp ls -ld /var/spool/postfix /var/spool/postfix/pid 2>/dev/null
echo ""

# 7. Verificar se o Postfix consegue fazer bind
echo "7. Testando se Postfix consegue fazer bind:"
docker-compose exec smtp postconf -n | grep -E "inet_interfaces|mydestination|virtual" | head -10
echo ""

# 8. Verificar processos Postfix
echo "8. Processos Postfix rodando:"
docker-compose exec smtp ps aux | grep -E "postfix|master|smtpd" | grep -v grep
echo ""

echo "=========================================="
echo "Diagnóstico concluído!"
echo "=========================================="
echo ""
echo "Para ver logs em tempo real:"
echo "  docker-compose logs -f smtp"
