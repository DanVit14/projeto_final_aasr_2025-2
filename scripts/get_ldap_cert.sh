#!/bin/bash
# Script para extrair e instalar o certificado CA do LDAP no container SMTP

set +e

echo "=========================================="
echo "Extraindo Certificado CA do LDAP"
echo "=========================================="
echo ""

# 1. Verificar se o certificado existe no LDAP
echo "1. Verificando certificado CA no container LDAP:"
docker-compose exec ldap ls -la /var/lib/samba/private/tls/ 2>&1 | grep -E "ca.pem|ca.crt" || echo "   Certificado não encontrado no caminho padrão"
echo ""

# 2. Tentar extrair o certificado do servidor LDAP
echo "2. Extraindo certificado do servidor LDAP via openssl:"
docker-compose exec smtp timeout 5 openssl s_client -connect ldap:636 -showcerts 2>&1 | \
  sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' | \
  tail -n +2 | head -n -1 > /tmp/ldap_ca.crt 2>&1

if [ -f /tmp/ldap_ca.crt ] && [ -s /tmp/ldap_ca.crt ]; then
    echo "   ✓ Certificado extraído com sucesso"
    echo "   Tamanho: $(wc -c < /tmp/ldap_ca.crt) bytes"
else
    echo "   ✗ Falha ao extrair certificado"
fi
echo ""

# 3. Tentar copiar do container LDAP diretamente
echo "3. Tentando copiar certificado do container LDAP:"
if docker-compose exec ldap test -f /var/lib/samba/private/tls/ca.pem 2>/dev/null; then
    echo "   Certificado encontrado em /var/lib/samba/private/tls/ca.pem"
    docker-compose exec ldap cat /var/lib/samba/private/tls/ca.pem > /tmp/ldap_ca_from_container.pem 2>&1
    if [ -f /tmp/ldap_ca_from_container.pem ] && [ -s /tmp/ldap_ca_from_container.pem ]; then
        echo "   ✓ Certificado copiado do container"
    fi
else
    echo "   Certificado não encontrado no caminho padrão"
fi
echo ""

# 4. Mostrar conteúdo do certificado (primeiras linhas)
if [ -f /tmp/ldap_ca.crt ] && [ -s /tmp/ldap_ca.crt ]; then
    echo "4. Conteúdo do certificado extraído (primeiras linhas):"
    head -5 /tmp/ldap_ca.crt
    echo "..."
    echo ""
fi

echo "=========================================="
echo "Certificado extraído em /tmp/ldap_ca.crt"
echo "=========================================="
