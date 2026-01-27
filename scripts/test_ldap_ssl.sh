#!/bin/bash
# Script para testar diferentes métodos de conexão LDAP/LDAPS

set +e

echo "=========================================="
echo "Testando Métodos de Conexão LDAP/LDAPS"
echo "=========================================="
echo ""

# 1. Testar LDAP simples (porta 389) sem TLS
echo "1. Testando LDAP simples (porta 389) sem TLS:"
docker-compose exec smtp ldapsearch -x -H ldap://ldap:389 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -10
echo ""

# 2. Testar LDAP com StartTLS (porta 389)
echo "2. Testando LDAP com StartTLS (porta 389):"
docker-compose exec smtp ldapsearch -x -H ldap://ldap:389 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -Z -LLL "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -10
echo ""

# 3. Testar LDAPS sem verificação de certificado
echo "3. Testando LDAPS sem verificação de certificado:"
docker-compose exec smtp ldapsearch -x -H ldaps://ldap:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL -o ldif-wrap=no "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -10
echo ""

# 4. Testar LDAPS ignorando certificado
echo "4. Testando LDAPS ignorando certificado:"
docker-compose exec smtp ldapsearch -x -H ldaps://ldap:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL -o ldif-wrap=no -o nettimeout=5 -o tls_require_cert=never "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -10
echo ""

# 5. Testar do container LDAP para localhost
echo "5. Testando do container LDAP para localhost (LDAPS):"
docker-compose exec ldap ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL -o ldif-wrap=no "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -10
echo ""

# 6. Testar do container LDAP para localhost (LDAP simples)
echo "6. Testando do container LDAP para localhost (LDAP simples):"
docker-compose exec ldap ldapsearch -x -H ldap://localhost:389 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -10
echo ""

# 7. Verificar certificado do LDAP
echo "7. Verificando certificado do servidor LDAP:"
docker-compose exec smtp timeout 3 openssl s_client -connect ldap:636 -showcerts 2>&1 | head -30
echo ""

# 8. Verificar configuração do Samba AD
echo "8. Verificando configuração do Samba AD (ldap server require strong auth):"
docker-compose exec ldap grep -i "ldap server require\|require strong\|tls\|ssl" /etc/samba/smb.conf 2>&1 | head -10
echo ""

# 9. Testar com IP direto ao invés de hostname
echo "9. Testando LDAPS usando IP direto (10.0.1.10):"
docker-compose exec smtp ldapsearch -x -H ldaps://10.0.1.10:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL -o ldif-wrap=no -o tls_require_cert=never "(mail=user1@empresa.local)" sAMAccountName 2>&1 | head -10
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
