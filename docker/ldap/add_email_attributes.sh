#!/bin/bash
# Script para adicionar atributos de e-mail aos usuários do LDAP
# Necessário para o Postfix funcionar corretamente

set +e

DOMAIN="${DOMAIN:-empresa.local}"
DOMAIN_DN="dc=$(echo $DOMAIN | sed 's/\./,dc=/g')"

echo "Adicionando atributos de e-mail aos usuários..."

# Verificar se o domínio foi provisionado
if [ ! -f "/var/lib/samba/private/sam.ldb" ]; then
    echo "   ERRO: Domínio ainda não foi provisionado!"
    exit 1
fi

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

# Tentar usar ldbmodify (caminho completo)
echo "Aplicando modificações LDAP usando ldbmodify..."
if command -v ldbmodify >/dev/null 2>&1; then
    ldbmodify -H /var/lib/samba/private/sam.ldb "$TMP_LDIF" 2>&1
    result=$?
elif [ -f /usr/bin/ldbmodify ]; then
    /usr/bin/ldbmodify -H /var/lib/samba/private/sam.ldb "$TMP_LDIF" 2>&1
    result=$?
else
    echo "   ldbmodify não encontrado, tentando método alternativo..."
    result=1
fi

# Se ldbmodify falhou, tentar usar samba-tool para cada usuário
if [ $result -ne 0 ]; then
    echo "   Usando samba-tool como alternativa..."
    
    # Usar samba-tool para adicionar atributos (se suportado)
    # Nota: samba-tool não tem comando direto para adicionar mail, então vamos tentar ldbmodify novamente
    # mas desta vez verificando se o arquivo existe
    if [ -f "$TMP_LDIF" ]; then
        # Tentar encontrar ldbmodify em outros locais comuns
        for ldb_path in /usr/bin/ldbmodify /usr/sbin/ldbmodify $(which ldbmodify 2>/dev/null); do
            if [ -x "$ldb_path" ]; then
                echo "   Usando $ldb_path..."
                "$ldb_path" -H /var/lib/samba/private/sam.ldb "$TMP_LDIF" 2>&1
                result=$?
                break
            fi
        done
    fi
fi

# Limpar arquivo temporário
rm -f "$TMP_LDIF"

if [ $result -eq 0 ]; then
    echo "✓ Atributos de e-mail adicionados aos usuários!"
else
    echo "⚠ Aviso: Pode ter havido problemas ao adicionar atributos."
    echo "   Verifique manualmente se os emails foram adicionados."
fi
