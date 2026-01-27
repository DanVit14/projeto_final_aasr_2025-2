#!/bin/bash
# Script para verificar o serviço pickup do Postfix

set +e

echo "=========================================="
echo "Verificando serviço pickup do Postfix"
echo "=========================================="
echo ""

# 1. Verificar se pickup está no master.cf
echo "1. Verificando master.cf para pickup:"
docker-compose exec smtp grep -E "^pickup|^#.*pickup" /etc/postfix/master.cf || echo "   pickup não encontrado (usando padrão)"
echo ""

# 2. Verificar se o processo pickup está rodando
echo "2. Processos pickup:"
docker-compose exec smtp ps aux | grep pickup | grep -v grep || echo "   Nenhum processo pickup rodando"
echo ""

# 3. Verificar diretório public
echo "3. Verificando diretório /var/spool/postfix/public:"
docker-compose exec smtp ls -ld /var/spool/postfix/public 2>&1
echo ""

# 4. Verificar se há arquivo pickup
echo "4. Verificando se há arquivo pickup em public:"
docker-compose exec smtp ls -la /var/spool/postfix/public/ 2>&1 | head -10
echo ""

# 5. Verificar configuração do queue_directory
echo "5. Configuração queue_directory do Postfix:"
docker-compose exec smtp postconf queue_directory
echo ""

# 6. Tentar criar o diretório e reiniciar
echo "6. Garantindo que diretórios existem:"
docker-compose exec smtp bash -c "mkdir -p /var/spool/postfix/public && chown postfix:postfix /var/spool/postfix/public && chmod 755 /var/spool/postfix/public && ls -ld /var/spool/postfix/public"
echo ""

# 7. Verificar se pickup inicia após reiniciar
echo "7. Reiniciando Postfix e verificando pickup:"
docker-compose exec smtp postfix reload 2>&1 | head -3
sleep 2
docker-compose exec smtp ps aux | grep pickup | grep -v grep || echo "   pickup ainda não está rodando"
echo ""

echo "=========================================="
echo "Verificação concluída!"
echo "=========================================="
