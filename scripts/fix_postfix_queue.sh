#!/bin/bash
# Script para corrigir problemas com a queue do Postfix

set +e

echo "=========================================="
echo "Corrigindo Queue do Postfix"
echo "=========================================="
echo ""

# 1. Parar Postfix
echo "1. Parando Postfix..."
docker-compose exec smtp postfix stop 2>&1
sleep 2
echo ""

# 2. Criar todos os diretórios necessários
echo "2. Criando diretórios de queue..."
docker-compose exec smtp bash -c '
mkdir -p /var/spool/postfix/public \
    /var/spool/postfix/maildrop \
    /var/spool/postfix/incoming \
    /var/spool/postfix/active \
    /var/spool/postfix/deferred \
    /var/spool/postfix/hold \
    /var/spool/postfix/bounce \
    /var/spool/postfix/pid \
    /var/spool/postfix/private \
    /var/spool/postfix/var/lib/sasl2

# Configurar propriedade e permissões corretas
# Diretório principal deve ser root:root
chown root:root /var/spool/postfix
chmod 755 /var/spool/postfix

# public e maildrop devem ser postfix:postdrop com setgid para postdrop funcionar
chown postfix:postdrop /var/spool/postfix/public /var/spool/postfix/maildrop
chmod 2755 /var/spool/postfix/public  # 2755 = rwxr-sr-x (setgid)
chmod 2775 /var/spool/postfix/maildrop  # 2775 = rwxrwsr-x (setgid + group write)

# Outros diretórios de queue devem ser postfix:postfix
chown postfix:postfix /var/spool/postfix/incoming \
    /var/spool/postfix/active \
    /var/spool/postfix/deferred \
    /var/spool/postfix/hold \
    /var/spool/postfix/bounce \
    /var/spool/postfix/pid \
    /var/spool/postfix/private 2>/dev/null || true

chmod 755 /var/spool/postfix/incoming
chmod 755 /var/spool/postfix/active
chmod 755 /var/spool/postfix/deferred
chmod 755 /var/spool/postfix/hold
chmod 755 /var/spool/postfix/bounce
chmod 700 /var/spool/postfix/private
'
echo "   Diretórios criados e permissões configuradas"
echo ""

# 3. Limpar arquivos de PID antigos
echo "3. Limpando arquivos de PID..."
docker-compose exec smtp rm -f /var/spool/postfix/pid/*.pid 2>/dev/null
echo ""

# 4. Verificar configuração
echo "4. Verificando configuração do Postfix:"
docker-compose exec smtp postfix check 2>&1
echo ""

# 5. Iniciar Postfix
echo "5. Iniciando Postfix..."
docker-compose exec smtp postfix start 2>&1
sleep 3
echo ""

# 6. Verificar status
echo "6. Status do Postfix:"
docker-compose exec smtp postfix status 2>&1
echo ""

# 7. Verificar processos
echo "7. Processos do Postfix:"
docker-compose exec smtp ps aux | grep -E "(postfix|master|pickup|qmgr|showq|virtual)" | grep -v grep
echo ""

# 8. Verificar sockets
echo "8. Verificando sockets criados:"
docker-compose exec smtp ls -la /var/spool/postfix/public/ 2>&1 | head -10
echo ""

# 9. Testar postqueue
echo "9. Testando postqueue:"
docker-compose exec smtp postqueue -p 2>&1 | head -5
echo ""

echo "=========================================="
echo "Correção concluída!"
echo "=========================================="
