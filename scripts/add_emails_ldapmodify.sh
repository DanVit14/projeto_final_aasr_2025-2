#!/bin/bash
# Script alternativo para adicionar emails usando ldapmodify via LDAP
# Funciona mesmo se ldbmodify não estiver disponível

set +e

echo "=========================================="
echo "Adicionando emails usando ldapmodify"
echo "=========================================="
echo ""

# Verificar se os containers estão rodando
if ! docker-compose ps | grep -q "ldap_ad.*Up"; then
    echo "ERRO: Container LDAP não está rodando!"
    exit 1
fi

if ! docker-compose ps | grep -q "smtp.*Up"; then
    echo "ERRO: Container SMTP não está rodando!"
    exit 1
fi

DOMAIN="empresa.local"
DOMAIN_DN="dc=empresa,dc=local"

# Criar arquivo LDIF temporário no host
TMP_LDIF=$(mktemp /tmp/add_emails_ldap_XXXXXX.ldif)

cat > "$TMP_LDIF" <<EOF
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

echo "1. Copiando arquivo LDIF para o container SMTP..."
docker cp "$TMP_LDIF" smtp:/tmp/add_emails.ldif

echo "2. Aplicando modificações usando ldapmodify do container SMTP..."
docker-compose exec -T smtp ldapmodify -x -H ldaps://ldap:636 \
    -D "cn=Administrator,cn=Users,${DOMAIN_DN}" \
    -w "Admin@123" \
    -f /tmp/add_emails.ldif 2>&1

result=$?

echo ""
echo "3. Limpando arquivo temporário..."
rm -f "$TMP_LDIF"
docker-compose exec -T smtp rm -f /tmp/add_emails.ldif 2>&1 >/dev/null

if [ $result -eq 0 ]; then
    echo ""
    echo "✓ Modificações aplicadas!"
    echo ""
    echo "4. Verificando se os emails foram adicionados..."
    sleep 2
    
    docker-compose exec -T smtp ldapsearch -x -H ldaps://ldap:636 \
        -b "${DOMAIN_DN}" \
        -D "cn=Administrator,cn=Users,${DOMAIN_DN}" \
        -w "Admin@123" \
        -LLL \
        "(&(objectClass=person)(mail=*))" \
        "sAMAccountName mail" 2>&1 | grep -v "^#" | head -20
    
    count=$(docker-compose exec -T smtp ldapsearch -x -H ldaps://ldap:636 \
        -b "${DOMAIN_DN}" \
        -D "cn=Administrator,cn=Users,${DOMAIN_DN}" \
        -w "Admin@123" \
        -LLL \
        "(&(objectClass=person)(mail=*))" \
        "mail" 2>&1 | grep -v "^#" | grep -c "^mail:" || echo "0")
    
    echo ""
    echo "   Total de usuários com email: $count"
    
    if [ "$count" -gt 0 ]; then
        echo ""
        echo "✓ Emails adicionados com sucesso!"
    else
        echo ""
        echo "⚠ Ainda não há emails. Pode ser necessário aguardar alguns segundos."
    fi
else
    echo ""
    echo "✗ ERRO ao aplicar modificações."
    echo "   Verifique os logs do container SMTP e LDAP."
fi

echo ""
echo "=========================================="
echo "Processo concluído!"
echo "=========================================="
