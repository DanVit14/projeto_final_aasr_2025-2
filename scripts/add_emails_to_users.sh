#!/bin/bash
# Script para adicionar atributos de e-mail aos usuários do LDAP
# Executa o script add_email_attributes.sh dentro do container LDAP

set +e

echo "=========================================="
echo "Adicionando emails aos usuários do LDAP"
echo "=========================================="
echo ""

# Verificar se o container está rodando
if ! docker-compose ps | grep -q "ldap_ad.*Up"; then
    echo "ERRO: Container LDAP não está rodando!"
    echo "Execute: docker-compose up -d ldap"
    exit 1
fi

echo "1. Executando script add_email_attributes.sh no container LDAP..."
docker-compose exec ldap /usr/local/bin/add_email_attributes.sh
echo ""

echo "2. Verificando se os emails foram adicionados..."
docker-compose exec ldap ldapsearch -x -H ldaps://localhost:636 \
    -b "dc=empresa,dc=local" \
    -D "cn=Administrator,cn=Users,dc=empresa,dc=local" \
    -w "Admin@123" \
    -LLL \
    "(&(objectClass=person)(mail=*))" \
    "sAMAccountName mail" 2>&1 | grep -v "^#" | head -20
echo ""

echo "3. Contando usuários com email:"
count=$(docker-compose exec ldap ldapsearch -x -H ldaps://localhost:636 \
    -b "dc=empresa,dc=local" \
    -D "cn=Administrator,cn=Users,dc=empresa,dc=local" \
    -w "Admin@123" \
    -LLL \
    "(&(objectClass=person)(mail=*))" \
    "mail" 2>&1 | grep -v "^#" | grep -c "^mail:" || echo "0")
echo "   Total de usuários com email: $count"
echo ""

if [ "$count" -gt 0 ]; then
    echo "✓ Emails adicionados com sucesso!"
    echo ""
    echo "Próximo passo: Execute o update-ldap-maps.sh para atualizar os arquivos hash:"
    echo "  ./scripts/update_ldap_maps_now.sh"
else
    echo "⚠ Ainda não há usuários com email. Verificando se o script foi executado..."
    echo ""
    echo "Tentando adicionar emails manualmente..."
    
    # Adicionar emails manualmente usando ldbmodify
    DOMAIN="empresa.local"
    DOMAIN_DN="dc=empresa,dc=local"
    
    echo "Adicionando email ao usuário admin..."
    docker-compose exec ldap ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF 2>&1
dn: CN=admin,CN=Users,${DOMAIN_DN}
changetype: modify
add: mail
mail: admin@${DOMAIN}
-
EOF

    echo "Adicionando email ao usuário user1..."
    docker-compose exec ldap ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF 2>&1
dn: CN=user1,CN=Users,${DOMAIN_DN}
changetype: modify
add: mail
mail: user1@${DOMAIN}
-
EOF

    echo "Adicionando email ao usuário user2..."
    docker-compose exec ldap ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF 2>&1
dn: CN=user2,CN=Users,${DOMAIN_DN}
changetype: modify
add: mail
mail: user2@${DOMAIN}
-
EOF

    echo "Adicionando email ao usuário Administrator..."
    docker-compose exec ldap ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF 2>&1
dn: CN=Administrator,CN=Users,${DOMAIN_DN}
changetype: modify
add: mail
mail: administrator@${DOMAIN}
-
EOF

    echo ""
    echo "Verificando novamente..."
    count=$(docker-compose exec ldap ldapsearch -x -H ldaps://localhost:636 \
        -b "dc=empresa,dc=local" \
        -D "cn=Administrator,cn=Users,dc=empresa,dc=local" \
        -w "Admin@123" \
        -LLL \
        "(&(objectClass=person)(mail=*))" \
        "mail" 2>&1 | grep -v "^#" | grep -c "^mail:" || echo "0")
    echo "   Total de usuários com email: $count"
    
    if [ "$count" -gt 0 ]; then
        echo "✓ Emails adicionados com sucesso!"
    else
        echo "✗ ERRO: Não foi possível adicionar emails. Verifique os logs do container LDAP."
    fi
fi

echo ""
echo "=========================================="
echo "Processo concluído!"
echo "=========================================="
