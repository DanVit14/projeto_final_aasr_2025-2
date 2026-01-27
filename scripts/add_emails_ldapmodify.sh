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

if ! docker-compose ps | grep -q "smtp_antivirus.*Up"; then
    echo "ERRO: Container SMTP não está rodando!"
    exit 1
fi

DOMAIN="empresa.local"
DOMAIN_DN="dc=empresa,dc=local"
BIND_DN="cn=Administrator,cn=Users,${DOMAIN_DN}"

# Obter DNs reais dos usuários (no Samba AD o CN pode ser "Admin User" etc.)
get_dn() {
    local user="$1"
    docker-compose exec -T smtp ldapsearch -x -H ldaps://ldap:636 \
        -b "cn=Users,${DOMAIN_DN}" \
        -D "$BIND_DN" -w "Admin@123" -LLL \
        "(&(objectClass=person)(sAMAccountName=${user}))" dn 2>/dev/null | grep "^dn:" | head -1 | sed 's/^dn: //'
}

# Criar arquivo LDIF temporário no host
TMP_LDIF=$(mktemp /tmp/add_emails_ldap_XXXXXX.ldif)

# Mapeamento usuário -> email
declare -A USER_EMAIL
USER_EMAIL[admin]="admin@${DOMAIN}"
USER_EMAIL[user1]="user1@${DOMAIN}"
USER_EMAIL[user2]="user2@${DOMAIN}"
USER_EMAIL[Administrator]="administrator@${DOMAIN}"

echo "   Obtendo DNs dos usuários no LDAP..."
> "$TMP_LDIF"
for user in admin user1 user2 Administrator; do
    dn=$(get_dn "$user")
    email="${USER_EMAIL[$user]}"
    if [ -z "$email" ]; then
        email="${user}@${DOMAIN}"
    fi
    if [ -n "$dn" ]; then
        cat >> "$TMP_LDIF" <<EOL
dn: ${dn}
changetype: modify
add: mail
mail: ${email}
-

EOL
        echo "   ✓ $user -> $dn"
    else
        # Fallback: CN igual ao nome do usuário (alguns ambientes)
        dn="CN=${user},CN=Users,${DOMAIN_DN}"
        cat >> "$TMP_LDIF" <<EOL
dn: ${dn}
changetype: modify
add: mail
mail: ${email}
-

EOL
        echo "   ⚠ $user: usando DN fallback $dn"
    fi
done

echo "1. Copiando arquivo LDIF para o container SMTP..."
docker cp "$TMP_LDIF" smtp_antivirus:/tmp/add_emails.ldif

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
