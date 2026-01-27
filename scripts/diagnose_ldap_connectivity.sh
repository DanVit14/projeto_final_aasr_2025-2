#!/bin/bash
# Script para diagnosticar conectividade LDAP entre containers

set +e

echo "=========================================="
echo "Diagnosticando Conectividade LDAP"
echo "=========================================="
echo ""

# 1. Verificar se o container LDAP está rodando
echo "1. Status do container LDAP:"
docker-compose ps ldap
echo ""

# 2. Verificar se o LDAP está escutando na porta 636
echo "2. Verificando se LDAP está escutando na porta 636:"
docker-compose exec ldap netstat -tlnp 2>/dev/null | grep ":636" || \
docker-compose exec ldap ss -tlnp 2>/dev/null | grep ":636" || \
docker-compose exec ldap lsof -i :636 2>/dev/null || \
echo "   Não foi possível verificar (ferramentas não disponíveis)"
echo ""

# 3. Testar conectividade de rede do container SMTP para LDAP
echo "3. Testando conectividade de rede (SMTP -> LDAP):"
echo "   Testando porta 389 (LDAP):"
docker-compose exec smtp timeout 3 nc -zv ldap 389 2>&1
echo ""
echo "   Testando porta 636 (LDAPS):"
docker-compose exec smtp timeout 3 nc -zv ldap 636 2>&1
echo ""

# 4. Verificar resolução DNS do hostname 'ldap'
echo "4. Verificando resolução DNS:"
docker-compose exec smtp getent hosts ldap 2>&1 || \
docker-compose exec smtp nslookup ldap 2>&1 || \
echo "   Erro ao resolver"
echo ""

# 5. Verificar se o Samba AD está configurado para LDAPS
echo "5. Verificando configuração do Samba AD para LDAPS:"
docker-compose exec ldap grep -i "ldaps\|636\|tls" /etc/samba/smb.conf 2>/dev/null | head -5 || \
echo "   Não foi possível verificar smb.conf"
echo ""

# 6. Verificar logs do LDAP para erros
echo "6. Últimas linhas dos logs do LDAP:"
docker-compose logs --tail=20 ldap 2>&1 | tail -10
echo ""

# 7. Testar conexão LDAPS do container LDAP para si mesmo
echo "7. Testando LDAPS do próprio container LDAP:"
docker-compose exec ldap ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(objectClass=*)"
echo ""

# 8. Verificar se o Samba está rodando
echo "8. Verificando processos do Samba:"
docker-compose exec ldap ps aux | grep -E "samba|ldap" | grep -v grep | head -5
echo ""

# 9. Verificar IP do container LDAP
echo "9. Verificando IP do container LDAP:"
docker-compose exec ldap hostname -I 2>&1 || docker-compose exec ldap ip addr show | grep "inet " | head -2
echo ""

# 10. Testar conexão usando IP direto
echo "10. Testando conexão usando IP direto (10.0.1.10):"
docker-compose exec smtp timeout 3 nc -zv 10.0.1.10 636 2>&1
echo ""

echo "=========================================="
echo "Diagnóstico concluído!"
echo "=========================================="
