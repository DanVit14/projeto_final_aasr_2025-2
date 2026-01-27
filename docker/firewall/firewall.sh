#!/bin/bash
# Script de inicialização do firewall

set -e

echo "Configurando firewall..."

# Carregar regras salvas
if [ -f /etc/iptables/rules.v4 ]; then
    iptables-restore < /etc/iptables/rules.v4
fi

# Encaminhar logs para logs-ntp
[ -f /etc/rsyslog.d/99-forward.conf ] && rsyslogd -n &
sleep 1

# Manter container rodando
tail -f /dev/null
