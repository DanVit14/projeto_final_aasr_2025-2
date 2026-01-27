#!/bin/bash
# Script para verificar se o smtpd está realmente escutando

set +e

echo "=========================================="
echo "Verificando se smtpd está escutando"
echo "=========================================="
echo ""

# 1. Ver processos smtpd
echo "1. Processos smtpd:"
docker-compose exec smtp ps aux 2>/dev/null | grep smtpd | grep -v grep
echo ""

# 2. Verificar se o Postfix master está escutando
echo "2. Verificando se Postfix master está escutando:"
docker-compose exec smtp bash -c "ss -tlnp 2>/dev/null | grep ':25 ' || netstat -tlnp 2>/dev/null | grep ':25 ' || echo 'Ferramentas não disponíveis'"
echo ""

# 3. Tentar conectar diretamente via bash TCP
echo "3. Testando conexão TCP direta (bash):"
docker-compose exec smtp bash -c 'timeout 2 bash -c "exec 3<>/dev/tcp/127.0.0.1/25 && cat <&3" 2>&1' | head -3 || echo "   Falhou ao conectar"
echo ""

# 4. Verificar se há algo bloqueando
echo "4. Verificando processos na porta 25:"
docker-compose exec smtp bash -c "fuser 25/tcp 2>/dev/null || lsof -i :25 2>/dev/null || echo 'Ferramentas não disponíveis'"
echo ""

# 5. Verificar configuração do inet_interfaces
echo "5. Configuração inet_interfaces:"
docker-compose exec smtp postconf inet_interfaces
echo ""

# 6. Verificar se o Postfix está realmente rodando
echo "6. Status detalhado do Postfix:"
docker-compose exec smtp postfix status 2>&1
echo ""

# 7. Tentar forçar o smtpd a iniciar
echo "7. Tentando forçar smtpd a escutar:"
docker-compose exec smtp bash -c "postfix reload 2>&1; sleep 2; postfix status 2>&1 | tail -1"
echo ""

# 8. Ver logs recentes para erros
echo "8. Últimas linhas dos logs (erros):"
docker-compose logs --tail=20 smtp 2>&1 | grep -iE "error|fatal|bind|listen|smtpd" | tail -5 || echo "   Nenhum erro encontrado"
echo ""

echo "=========================================="
echo "Diagnóstico concluído!"
echo "=========================================="
