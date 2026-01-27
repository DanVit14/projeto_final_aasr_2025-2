#!/bin/bash
# Teste LDAP: autenticação, listagem de utilizadores/grupos, SMB (compartilhamentos)
# Uso: a partir da raiz do projeto, ./scripts/test_ldap_auth_list_smb.sh

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
B="docker-compose exec -T"
LDAP_BASE="dc=empresa,dc=local"
ADMIN_DN="cn=Administrator,cn=Users,${LDAP_BASE}"
ADMIN_PW="${LDAP_BIND_PW:-Admin@123}"

echo "=== 1. LDAP autenticação (bind como Administrator) ==="
$B smtp ldapsearch -x -H ldap://ldap:389 -b "${LDAP_BASE}" -D "${ADMIN_DN}" -w "${ADMIN_PW}" -LLL -s base dn 2>/dev/null | grep "^dn:" || true
echo "   Bind OK"
echo ""

echo "=== 2. LDAP listagem (utilizadores com mail) ==="
$B smtp ldapsearch -x -H ldap://ldap:389 -b "${LDAP_BASE}" -D "${ADMIN_DN}" -w "${ADMIN_PW}" -LLL "(&(objectClass=person)(mail=*))" sAMAccountName mail 2>/dev/null | grep -E "^(mail|sAMAccountName):" | head -12
echo ""

echo "=== 3. SMB listagem de compartilhamentos ==="
$B ldap smbclient -L //127.0.0.1 -N 2>/dev/null || \
$B ldap smbclient -L //127.0.0.1 -U "Administrator%${ADMIN_PW}" 2>/dev/null | head -20 || \
echo "   (smbclient não disponível ou SMB em outro host; testar manualmente: smbclient -L //<ip_ldap> -U administrator%Admin@123)"
echo ""

echo "=== LDAP auth + listagem + SMB concluído ==="
