#!/bin/bash
# Script para diagnosticar e corrigir problema do smtpd não escutando

set +e

echo "=========================================="
echo "Diagnosticando e corrigindo smtpd"
echo "=========================================="
echo ""

# 1. Verificar se há algo escutando na porta 25
echo "1. Verificando o que está na porta 25:"
docker-compose exec smtp bash -c "ss -tlnp 2>/dev/null | grep ':25 ' || netstat -tlnp 2>/dev/null | grep ':25 ' || lsof -i :25 2>/dev/null || echo '   Ferramentas não disponíveis - tentando método alternativo'"
echo ""

# 2. Verificar se o Postfix master está realmente escutando
echo "2. Verificando processos do Postfix master:"
docker-compose exec smtp ps aux | grep "master" | grep -v grep
echo ""

# 3. Verificar configuração do master.cf
echo "3. Verificando master.cf (linha smtp):"
docker-compose exec smtp grep "^smtp" /etc/postfix/master.cf
echo ""

# 4. Verificar se há problema com chroot
echo "4. Verificando configuração de chroot:"
docker-compose exec smtp postconf | grep -E "queue_directory|daemon_directory" | head -5
echo ""

# 5. Tentar forçar o smtpd a escutar
echo "5. Tentando forçar smtpd a escutar:"
docker-compose exec smtp bash -c "postfix stop; sleep 2; postfix start; sleep 3; postfix status"
echo ""

# 6. Verificar logs do Postfix para erros específicos
echo "6. Verificando logs do Postfix para erros:"
docker-compose logs smtp 2>&1 | grep -iE "smtpd.*bind|smtpd.*listen|smtpd.*error|smtpd.*fail|cannot.*bind.*25" | tail -10 || echo "   Nenhum erro específico encontrado"
echo ""

# 7. Testar se consegue fazer bind manualmente
echo "7. Testando se a porta 25 está acessível:"
docker-compose exec smtp bash -c "timeout 2 bash -c 'exec 3<>/dev/tcp/localhost/25' 2>&1 && echo '   Porta 25 está acessível' || echo '   Porta 25 NÃO está acessível'"
echo ""

echo "=========================================="
echo "Diagnóstico concluído!"
echo "=========================================="
