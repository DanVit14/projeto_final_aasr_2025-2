#!/bin/bash
# Script de inicialização do firewall

set -e

echo "Configurando firewall..."

# Carregar regras salvas
if [ -f /etc/iptables/rules.v4 ]; then
    iptables-restore < /etc/iptables/rules.v4
fi

# Configurar port forwarding para PostgreSQL (integração com teste E2E)
if [ -f /usr/local/bin/setup_forward.sh ]; then
    bash /usr/local/bin/setup_forward.sh
fi

# Encaminhar logs para logs-ntp
[ -f /etc/rsyslog.d/99-forward.conf ] && rsyslogd -n &
sleep 1

# Manter container rodando
tail -f /dev/null
