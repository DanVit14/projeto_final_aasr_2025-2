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
docker-compose exec -T ldap /usr/local/bin/add_email_attributes.sh 2>&1
echo ""

echo "2. Aguardando 3 segundos para LDAP processar as mudanças..."
sleep 3
echo ""

echo "3. Verificando se os emails foram adicionados..."
# Verificar do container SMTP (que é quem vai usar o LDAP)
result=$(docker-compose exec -T smtp ldapsearch -x -H ldaps://ldap:636 \
    -b "dc=empresa,dc=local" \
    -D "cn=Administrator,cn=Users,dc=empresa,dc=local" \
    -w "Admin@123" \
    -LLL \
    "(&(objectClass=person)(mail=*))" \
    "sAMAccountName mail" 2>&1 | grep -v "^#")

if [ -n "$result" ] && echo "$result" | grep -q "^mail:"; then
    echo "$result" | head -20
    echo ""
else
    echo "   (Nenhum resultado encontrado ainda)"
    echo ""
fi

echo "4. Contando usuários com email:"
# Contar do container SMTP
count=$(docker-compose exec -T smtp ldapsearch -x -H ldaps://ldap:636 \
    -b "dc=empresa,dc=local" \
    -D "cn=Administrator,cn=Users,dc=empresa,dc=local" \
    -w "Admin@123" \
    -LLL \
    "(&(objectClass=person)(mail=*))" \
    "mail" 2>&1 | grep -v "^#" | grep -c "^mail:" 2>/dev/null || echo "0")

echo "   Total de usuários com email: $count"
echo ""

# Verificar se count é um número válido
if ! [[ "$count" =~ ^[0-9]+$ ]]; then
    count=0
fi

if [ "$count" -gt 0 ]; then
    echo "✓ Emails adicionados com sucesso!"
    echo ""
    echo "Próximo passo: Execute o update-ldap-maps.sh para atualizar os arquivos hash:"
    echo "  ./scripts/update_ldap_maps_now.sh"
else
    echo "⚠ Ainda não há usuários com email. Tentando adicionar manualmente..."
    echo ""
    
    # Adicionar emails manualmente usando ldbmodify via arquivo temporário
    DOMAIN="empresa.local"
    DOMAIN_DN="dc=empresa,dc=local"
    
    # Criar arquivo LDIF temporário
    cat > /tmp/add_emails.ldif <<EOF
dn: CN=admin,CN=Users,${DOMAIN_DN}
changetype: modify
add: mail
mail: admin@${DOMAIN}
-
dn: CN=user1,CN=Users,${DOMAIN_DN}
changetype: modify
add: mail
mail: user1@${DOMAIN}
-
dn: CN=user2,CN=Users,${DOMAIN_DN}
changetype: modify
add: mail
mail: user2@${DOMAIN}
-
dn: CN=Administrator,CN=Users,${DOMAIN_DN}
changetype: modify
add: mail
mail: administrator@${DOMAIN}
-
EOF

    echo "Adicionando emails usando ldbmodify..."
    docker-compose exec -T ldap ldbmodify -H /var/lib/samba/private/sam.ldb < /tmp/add_emails.ldif 2>&1
    rm -f /tmp/add_emails.ldif
    
    echo ""
    echo "Aguardando 3 segundos..."
    sleep 3
    echo ""
    
    echo "Verificando novamente..."
    result=$(docker-compose exec -T ldap ldapsearch -x -H ldaps://localhost:636 \
        -b "dc=empresa,dc=local" \
        -D "cn=Administrator,cn=Users,dc=empresa,dc=local" \
        -w "Admin@123" \
        -LLL \
        "(&(objectClass=person)(mail=*))" \
        "mail" 2>&1 | grep -v "^#")
    
    count=$(echo "$result" | grep -c "^mail:" 2>/dev/null || echo "0")
    
    # Verificar se count é um número válido
    if ! [[ "$count" =~ ^[0-9]+$ ]]; then
        count=0
    fi
    
    echo "   Total de usuários com email: $count"
    
    if [ "$count" -gt 0 ]; then
        echo "✓ Emails adicionados com sucesso!"
        echo ""
        echo "Listando emails encontrados:"
        echo "$result" | grep "^mail:" | head -10
    else
        echo "✗ ERRO: Não foi possível adicionar emails."
        echo ""
        echo "Tentando método alternativo usando samba-tool..."
        
    # Tentar usar samba-tool para verificar usuários
    echo "Verificando usuários existentes:"
    docker-compose exec -T ldap samba-tool user list 2>&1 | head -10
        
        # Usar samba-tool para modificar atributos (se suportado)
        echo "Nota: Pode ser necessário adicionar emails manualmente usando:"
        echo "  docker-compose exec ldap samba-tool user edit admin"
        echo "  (e então adicionar o atributo mail: admin@empresa.local)"
    fi
fi

echo ""
echo "=========================================="
echo "Processo concluído!"
echo "=========================================="
