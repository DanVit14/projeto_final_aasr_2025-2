#!/bin/bash
# Script para encontrar ldbmodify e adicionar emails

set +e

echo "=========================================="
echo "Procurando ldbmodify e adicionando emails"
echo "=========================================="
echo ""

# Verificar se o container está rodando
if ! docker-compose ps | grep -q "ldap_ad.*Up"; then
    echo "ERRO: Container LDAP não está rodando!"
    exit 1
fi

echo "1. Procurando ldbmodify no container LDAP..."
docker-compose exec -T ldap bash -c "
    echo 'Procurando ldbmodify...'
    which ldbmodify 2>/dev/null || echo '   Não encontrado em PATH'
    find /usr -name ldbmodify 2>/dev/null | head -5
    find /usr/bin -name '*ldb*' 2>/dev/null | head -10
    echo ''
    echo 'Verificando pacotes instalados:'
    dpkg -l | grep -i samba | grep -i ldb | head -5
"
echo ""

echo "2. Tentando executar add_email_attributes.sh diretamente..."
docker-compose exec ldap /usr/local/bin/add_email_attributes.sh
echo ""

echo "3. Verificando se funcionou (do container SMTP)..."
sleep 3

if docker-compose ps | grep -q "smtp.*Up"; then
    count=$(docker-compose exec -T smtp ldapsearch -x -H ldaps://ldap:636 \
        -b "dc=empresa,dc=local" \
        -D "cn=Administrator,cn=Users,dc=empresa,dc=local" \
        -w "Admin@123" \
        -LLL \
        "(&(objectClass=person)(mail=*))" \
        "mail" 2>&1 | grep -v "^#" | grep -c "^mail:" || echo "0")
    
    echo "   Total de usuários com email: $count"
    
    if [ "$count" -gt 0 ]; then
        echo ""
        echo "✓ Emails encontrados!"
        docker-compose exec -T smtp ldapsearch -x -H ldaps://ldap:636 \
            -b "dc=empresa,dc=local" \
            -D "cn=Administrator,cn=Users,dc=empresa,dc=local" \
            -w "Admin@123" \
            -LLL \
            "(&(objectClass=person)(mail=*))" \
            "sAMAccountName mail" 2>&1 | grep -v "^#" | head -15
    else
        echo ""
        echo "⚠ Ainda não há emails. Tente usar:"
        echo "   ./scripts/add_emails_ldapmodify.sh"
    fi
else
    echo "   Container SMTP não está rodando, não é possível verificar."
fi

echo ""
echo "=========================================="
echo "Processo concluído!"
echo "=========================================="
