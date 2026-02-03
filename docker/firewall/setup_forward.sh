#!/bin/bash
# Configurar port forwarding do PostgreSQL através do Firewall
# Cliente → Firewall:5432 → Database:5432

set -e

echo "Configurando port forwarding para PostgreSQL..."

# Habilitar IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Limpar regras antigas de NAT
iptables -t nat -F

# PREROUTING: Redirecionar tráfego chegando na porta 5432 do firewall para o database
iptables -t nat -A PREROUTING -p tcp --dport 5432 -j DNAT --to-destination 10.0.1.40:5432

# POSTROUTING: Mascarar origem para que database responda de volta ao firewall
iptables -t nat -A POSTROUTING -p tcp -d 10.0.1.40 --dport 5432 -j MASQUERADE

# FORWARD: Permitir tráfego forwarded para o database
iptables -A FORWARD -p tcp -d 10.0.1.40 --dport 5432 -j ACCEPT
iptables -A FORWARD -p tcp -s 10.0.1.40 --sport 5432 -j ACCEPT

# LOG: Registrar conexões ao PostgreSQL (para evidência)
iptables -A FORWARD -p tcp --dport 5432 -j LOG --log-prefix "[FW-DB] " --log-level 4

echo "✓ Port forwarding configurado:"
echo "  Cliente → Firewall:5432 → Database:5432"
echo ""
echo "Regras NAT ativas:"
iptables -t nat -L -n -v
echo ""
echo "Regras FORWARD ativas:"
iptables -L FORWARD -n -v
