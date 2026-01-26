#!/bin/bash
# Script de inicialização do firewall

set -e

echo "Configurando firewall..."

# Carregar regras salvas
if [ -f /etc/iptables/rules.v4 ]; then
    iptables-restore < /etc/iptables/rules.v4
fi

# Manter container rodando
tail -f /dev/null
