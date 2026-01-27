#!/bin/bash
# Script wrapper para consulta LDAP quando postmap não funciona diretamente
# Este script é chamado pelo Postfix via lookup type "external"
# 
# Uso no Postfix: external:/usr/local/bin/ldap-wrapper.sh mailbox
# O Postfix passa a chave (email) como argumento: /usr/local/bin/ldap-wrapper.sh mailbox user1@empresa.local
#
# Referência: Problema conhecido com Postfix LDAP em containers Docker
# https://github.com/docker-mailserver/docker-mailserver/issues/1468

set +e

# Configurações LDAP (podem ser sobrescritas por variáveis de ambiente)
LDAP_SERVER="${LDAP_SERVER:-ldap}"
LDAP_PORT="${LDAP_PORT:-636}"
LDAP_BASE="${LDAP_BASE:-dc=empresa,dc=local}"
LDAP_BIND_DN="${LDAP_BIND_DN:-cn=Administrator,cn=Users,dc=empresa,dc=local}"
LDAP_BIND_PW="${LDAP_BIND_PW:-Admin@123}"

# O Postfix passa: tipo_de_consulta chave
# Exemplo: mailbox user1@empresa.local
QUERY_TYPE="$1"
KEY="$2"

# Função para consultar LDAP
query_ldap() {
    local filter="$1"
    local attribute="$2"
    local format="$3"
    
    # Tentar LDAPS primeiro (porta 636)
    local result=$(ldapsearch -x -H ldaps://${LDAP_SERVER}:${LDAP_PORT} \
        -b "${LDAP_BASE}" \
        -D "${LDAP_BIND_DN}" \
        -w "${LDAP_BIND_PW}" \
        -LLL \
        -o nettimeout=5 \
        "${filter}" \
        "${attribute}" 2>/dev/null | grep "^${attribute}:" | head -1 | cut -d: -f2 | tr -d " ")
    
    # Se falhar, tentar LDAP com StartTLS (porta 389)
    if [ -z "$result" ]; then
        result=$(ldapsearch -x -H ldap://${LDAP_SERVER}:389 \
            -b "${LDAP_BASE}" \
            -D "${LDAP_BIND_DN}" \
            -w "${LDAP_BIND_PW}" \
            -ZZ \
            -LLL \
            -o nettimeout=5 \
            "${filter}" \
            "${attribute}" 2>/dev/null | grep "^${attribute}:" | head -1 | cut -d: -f2 | tr -d " ")
    fi
    
    # Se encontrou resultado, formatar conforme necessário
    if [ -n "$result" ]; then
        if [ -n "$format" ]; then
            # Substituir %d pelo domínio e %s pelo resultado
            local domain=$(echo "$KEY" | cut -d@ -f2 2>/dev/null || echo "empresa.local")
            echo "$format" | sed "s|%d|$domain|g" | sed "s|%s|$result|g"
        else
            echo "$result"
        fi
    fi
}

# Processar diferentes tipos de consulta
case "$QUERY_TYPE" in
    mailbox)
        # Consulta para caixa de correio: buscar sAMAccountName pelo email
        # KEY = user1@empresa.local
        if [ -z "$KEY" ]; then
            exit 1
        fi
        query_ldap "(&(objectClass=person)(mail=${KEY}))" "sAMAccountName" "empresa.local/%s/Maildir/"
        ;;
    domain)
        # Consulta para domínio: verificar se existe usuário com esse domínio
        # KEY = empresa.local
        if [ -z "$KEY" ]; then
            exit 1
        fi
        result=$(query_ldap "(&(objectClass=person)(mail=*@${KEY}))" "mail" "")
        if [ -n "$result" ]; then
            echo "$KEY"
        fi
        ;;
    alias)
        # Consulta para alias: retornar o próprio email (aliases serão configurados manualmente)
        # KEY = user1@empresa.local
        if [ -z "$KEY" ]; then
            exit 1
        fi
        result=$(query_ldap "(&(objectClass=person)(mail=${KEY}))" "mail" "")
        if [ -n "$result" ]; then
            echo "$result"
        fi
        ;;
    sender)
        # Consulta para sender login: buscar sAMAccountName pelo email
        # KEY = user1@empresa.local
        if [ -z "$KEY" ]; then
            exit 1
        fi
        query_ldap "(&(objectClass=person)(mail=${KEY}))" "sAMAccountName" ""
        ;;
    *)
        echo "Uso: $0 [mailbox|domain|alias|sender] [key]" >&2
        exit 1
        ;;
esac
