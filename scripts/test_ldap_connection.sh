#!/bin/bash
# Script para testar conexão LDAP do container SMTP

set +e

echo "=========================================="
echo "Testando Conexão LDAP do SMTP"
echo "=========================================="
echo ""

# 1. Verificar se o container LDAP está rodando
echo "1. Status do container LDAP:"
docker-compose ps ldap
echo ""

# 2. Testar conexão LDAP do container SMTP
echo "2. Testando conexão LDAP do container SMTP:"
echo "   Testando LDAP na porta 389 (StartTLS):"
docker-compose exec smtp bash -c "echo | timeout 3 openssl s_client -starttls ldap -connect ldap:389 2>&1 | head -5" || echo "   Erro ao conectar"
echo ""

# 3. Testar conexão LDAP simples
echo "3. Testando conexão LDAP simples (porta 389):"
docker-compose exec smtp bash -c "timeout 3 nc -zv ldap 389 2>&1" || echo "   Erro ao conectar"
echo ""

# 4. Testar conexão LDAPS (porta 636)
echo "4. Testando conexão LDAPS (porta 636):"
docker-compose exec smtp bash -c "timeout 3 nc -zv ldap 636 2>&1" || echo "   Erro ao conectar"
echo ""

# 5. Testar resolução DNS do hostname ldap
echo "5. Testando resolução DNS do hostname 'ldap':"
docker-compose exec smtp getent hosts ldap 2>&1 || docker-compose exec smtp nslookup ldap 2>&1 || echo "   Erro ao resolver"
echo ""

# 6. Testar consulta LDAP usando ldapsearch
echo "6. Testando consulta LDAP usando ldapsearch:"
docker-compose exec smtp ldapsearch -x -H ldap://ldap:389 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL "(mail=user1@empresa.local)" mail sAMAccountName 2>&1 | head -10
echo ""

# 7. Testar consulta LDAP com StartTLS
echo "7. Testando consulta LDAP com StartTLS:"
docker-compose exec smtp ldapsearch -x -H ldap://ldap:389 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" -LLL -Z "(mail=user1@empresa.local)" mail sAMAccountName 2>&1 | head -10
echo ""

# 8. Testar resolução Postfix do destinatário
echo "8. Testando resolução Postfix do destinatário:"
echo "   Domínio:"
docker-compose exec smtp postmap -q empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-domains.cf 2>&1
echo ""
echo "   Usuário:"
docker-compose exec smtp postmap -q user1@empresa.local ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

# 9. Verificar configuração LDAP do Postfix
echo "9. Verificando arquivos de configuração LDAP:"
docker-compose exec smtp ls -la /etc/postfix/ldap/ 2>&1
echo ""

# 10. Verificar conteúdo do arquivo ldap-virtual-mailbox-maps.cf
echo "10. Conteúdo do ldap-virtual-mailbox-maps.cf:"
docker-compose exec smtp cat /etc/postfix/ldap/ldap-virtual-mailbox-maps.cf 2>&1
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
