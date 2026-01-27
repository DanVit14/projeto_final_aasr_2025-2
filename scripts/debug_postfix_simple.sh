#!/bin/bash
# Script de debug simplificado do Postfix (mostra apenas o essencial)

set +e

echo "=========================================="
echo "Debug Simplificado do Postfix"
echo "=========================================="
echo ""

# 1. Status do container
echo "1. Container está rodando?"
docker-compose ps smtp | grep smtp_antivirus
echo ""

# 2. Processo Postfix
echo "2. Processo Postfix existe?"
docker-compose exec smtp ps aux 2>/dev/null | grep -E "postfix|master" | grep -v grep || echo "   ✗ Nenhum processo Postfix encontrado"
echo ""

# 3. Status do Postfix
echo "3. Status do Postfix:"
docker-compose exec smtp postfix status 2>&1 | head -5
echo ""

# 4. Últimas 10 linhas dos logs
echo "4. Últimas 10 linhas dos logs:"
docker-compose logs --tail=10 smtp 2>&1 | tail -10
echo ""

# 5. Tentar iniciar Postfix
echo "5. Tentando iniciar Postfix:"
docker-compose exec smtp postfix start 2>&1 | head -3
echo ""

# 6. Verificar porta 25 (método simples)
echo "6. Testando porta 25:"
if echo "QUIT" | timeout 2 docker-compose exec -T smtp nc localhost 25 2>&1 | grep -q "220"; then
    echo "   ✓ Postfix está respondendo"
else
    echo "   ✗ Postfix NÃO está respondendo"
fi
echo ""

echo "=========================================="
echo "Debug simplificado concluído!"
echo "=========================================="
echo ""
echo "Para ver logs completos: docker-compose logs smtp | tail -50"
