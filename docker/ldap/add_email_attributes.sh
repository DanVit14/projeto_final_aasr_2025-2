#!/bin/bash
# Script para adicionar atributos de e-mail aos usuários do LDAP
# Necessário para o Postfix funcionar corretamente

set +e

DOMAIN="${DOMAIN:-empresa.local}"
DOMAIN_DN="dc=$(echo $DOMAIN | sed 's/\./,dc=/g')"

echo "Adicionando atributos de e-mail aos usuários..."

# Criar arquivo LDIF temporário
TMP_LDIF=$(mktemp /tmp/add_emails_XXXXXX.ldif)

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

# Aplicar modificações usando ldbmodify
echo "Aplicando modificações LDAP..."
ldbmodify -H /var/lib/samba/private/sam.ldb "$TMP_LDIF" 2>&1

# Limpar arquivo temporário
rm -f "$TMP_LDIF"

echo "Atributos de e-mail adicionados aos usuários!"
