#!/bin/bash
# Script de debug detalhado do Postfix

set +e

OUTPUT_FILE="/tmp/postfix_debug_$(date +%Y%m%d_%H%M%S).log"

echo "=========================================="
echo "Debug Detalhado do Postfix"
echo "=========================================="
echo "Salvando saída completa em: $OUTPUT_FILE"
echo ""

# Redirecionar tudo para o arquivo também
exec > >(tee -a "$OUTPUT_FILE")
exec 2>&1

# 1. Verificar se o container está rodando
echo "1. Status do container:"
docker-compose ps smtp
echo ""

# 2. Ver todos os processos dentro do container
echo "2. Todos os processos no container:"
docker-compose exec smtp ps aux
echo ""

# 3. Verificar se o Postfix está rodando
echo "3. Processos Postfix:"
docker-compose exec smtp ps aux | grep -i postfix
echo ""

# 4. Tentar verificar status do Postfix
echo "4. Status do Postfix (comando postfix status):"
docker-compose exec smtp postfix status 2>&1
echo ""

# 5. Verificar configuração do Postfix
echo "5. Verificando configuração (postfix check):"
docker-compose exec smtp postfix check 2>&1
echo ""

# 6. Ver logs completos do container
echo "6. Últimas 30 linhas dos logs:"
docker-compose logs --tail=30 smtp
echo ""

# 7. Verificar se há arquivos de PID do Postfix
echo "7. Arquivos de PID do Postfix:"
docker-compose exec smtp ls -la /var/spool/postfix/pid/ 2>/dev/null || echo "   Diretório não existe ou não acessível"
echo ""

# 8. Verificar permissões dos diretórios do Postfix
echo "8. Permissões dos diretórios principais:"
docker-compose exec smtp ls -ld /var/spool/postfix /etc/postfix /var/mail 2>/dev/null
echo ""

# 9. Tentar iniciar o Postfix manualmente e ver o erro
echo "9. Tentando iniciar Postfix manualmente:"
docker-compose exec smtp postfix start 2>&1
echo ""

# 10. Verificar portas usando lsof (se disponível)
echo "10. Portas abertas (lsof):"
docker-compose exec smtp lsof -i :25 2>/dev/null || echo "   lsof não disponível ou nenhum processo na porta 25"
echo ""

# 11. Verificar se o Postfix consegue fazer bind
echo "11. Testando se a porta 25 está em uso:"
docker-compose exec smtp fuser 25/tcp 2>/dev/null || echo "   fuser não disponível ou porta não em uso"
echo ""

echo "=========================================="
echo "Debug concluído!"
echo "=========================================="
echo ""
echo "Saída completa salva em: $OUTPUT_FILE"
echo "Para ver o arquivo: cat $OUTPUT_FILE"
echo "Para ver as últimas linhas: tail -50 $OUTPUT_FILE"
