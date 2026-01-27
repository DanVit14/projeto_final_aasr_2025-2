#!/bin/bash
# Script para verificar status detalhado do Postfix

set +e

echo "=========================================="
echo "Verificação Detalhada do Postfix"
echo "=========================================="
echo ""

# 1. Verificar se o processo Postfix está rodando
echo "1. Processos Postfix:"
docker-compose exec smtp ps aux | grep -E "postfix|master" | grep -v grep
echo ""

# 2. Verificar status do Postfix
echo "2. Status do Postfix:"
docker-compose exec smtp postfix status 2>&1
echo ""

# 3. Verificar portas abertas
echo "3. Portas abertas no container:"
docker-compose exec smtp netstat -tlnp 2>/dev/null | grep -E ":(25|587)" || docker-compose exec smtp ss -tlnp 2>/dev/null | grep -E ":(25|587)"
echo ""

# 4. Verificar logs recentes do Postfix
echo "4. Últimas 20 linhas dos logs do Postfix:"
docker-compose logs --tail=20 smtp | grep -i postfix
echo ""

# 5. Verificar erros nos logs
echo "5. Erros recentes nos logs:"
docker-compose logs --tail=50 smtp | grep -iE "error|fatal|fail|cannot" | tail -10
echo ""

# 6. Testar conexão local dentro do container
echo "6. Testando conexão SMTP local (dentro do container):"
echo "QUIT" | docker-compose exec -T smtp nc localhost 25 2>&1 | head -3
echo ""

# 7. Verificar configuração do Postfix
echo "7. Verificando configuração:"
docker-compose exec smtp postfix check 2>&1
echo ""

echo "=========================================="
echo "Verificação concluída!"
echo "=========================================="
