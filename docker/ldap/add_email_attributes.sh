#!/bin/bash
# Script para adicionar atributos de e-mail aos usuários do LDAP
# Necessário para o Postfix funcionar corretamente

set +e

DOMAIN="${DOMAIN:-empresa.local}"
DOMAIN_DN="dc=$(echo $DOMAIN | sed 's/\./,dc=/g')"

echo "Adicionando atributos de e-mail aos usuários..."

# Adicionar atributo mail ao usuário admin
samba-tool user setpassword admin --newpassword="Admin@123" --must-change-at-next-login=no 2>/dev/null || true
ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF 2>/dev/null
dn: CN=admin,CN=Users,${DOMAIN_DN}
changetype: modify
add: mail
mail: admin@${DOMAIN}
-
EOF

# Adicionar atributo mail ao usuário user1
ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF 2>/dev/null
dn: CN=user1,CN=Users,${DOMAIN_DN}
changetype: modify
add: mail
mail: user1@${DOMAIN}
-
EOF

# Adicionar atributo mail ao usuário user2
ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF 2>/dev/null
dn: CN=user2,CN=Users,${DOMAIN_DN}
changetype: modify
add: mail
mail: user2@${DOMAIN}
-
EOF

# Adicionar atributo mail ao Administrator
ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF 2>/dev/null
dn: CN=Administrator,CN=Users,${DOMAIN_DN}
changetype: modify
add: mail
mail: administrator@${DOMAIN}
-
EOF

echo "Atributos de e-mail adicionados aos usuários!"
