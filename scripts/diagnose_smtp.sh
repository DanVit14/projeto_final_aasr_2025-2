#!/bin/bash
# Script de diagnóstico do SMTP

echo "=========================================="
echo "Diagnóstico do SMTP"
echo "=========================================="
echo ""

# 1. Status do container
echo "1. Status do container SMTP:"
docker-compose ps smtp
echo ""

# 2. Verificar se o Postfix está rodando
echo "2. Processos dentro do container:"
docker-compose exec smtp ps aux 2>/dev/null | grep -E "postfix|dovecot|clam|amavis" || echo "   Container não está rodando ou não consegue executar comandos"
echo ""

# 3. Testar conexão LDAP do container SMTP
echo "3. Testando conexão LDAP do container SMTP:"
echo "   Tentando LDAP (porta 389)..."
docker-compose exec smtp ldapsearch -x -H ldap://ldap:389 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" 2>&1 | head -5
echo ""
echo "   Tentando LDAPS (porta 636)..."
docker-compose exec smtp ldapsearch -x -H ldaps://ldap:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" 2>&1 | head -5
echo ""

# 4. Verificar se o LDAP está acessível do host
echo "4. Testando LDAP do host:"
echo "   Tentando LDAP (porta 389)..."
ldapsearch -x -H ldap://localhost:389 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" 2>&1 | head -3 || echo "   Falhou"
echo ""

# 5. Verificar logs recentes
echo "5. Últimas 10 linhas dos logs:"
docker-compose logs --tail=10 smtp
echo ""

# 6. Verificar se o Postfix consegue verificar configuração
echo "6. Verificando configuração do Postfix:"
docker-compose exec smtp postfix check 2>&1 || echo "   Postfix não está acessível"
echo ""

echo "=========================================="
echo "Diagnóstico concluído!"
echo "=========================================="
