#!/bin/bash
# Configurar port forwarding do PostgreSQL através do Firewall
# Cliente → Firewall:5432 → Database:5432

# NÃO usar set -e para não crashar container se algo falhar
# set -e

echo "Configurando port forwarding para PostgreSQL..."

# Habilitar IP forwarding
if echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null; then
    echo "  ✓ IP forwarding habilitado"
else
    echo "  ⚠ Não foi possível habilitar IP forwarding (pode já estar ativo)"
fi

# Aguardar um pouco para rede estar pronta
sleep 2

# Limpar regras antigas de NAT (não-fatal se falhar)
if iptables -t nat -F 2>/dev/null; then
    echo "  ✓ Regras NAT limpas"
else
    echo "  ⚠ Não foi possível limpar NAT (pode não ter regras antigas)"
fi

# PREROUTING: Redirecionar tráfego chegando na porta 5432 do firewall para o database
if iptables -t nat -A PREROUTING -p tcp --dport 5432 -j DNAT --to-destination 10.0.1.40:5432 2>/dev/null; then
    echo "  ✓ PREROUTING (DNAT) configurado"
else
    echo "  ✗ ERRO: Não foi possível configurar PREROUTING"
    exit 0  # Sair gracefully, não crashar container
fi

# POSTROUTING: Mascarar origem para que database responda de volta ao firewall
if iptables -t nat -A POSTROUTING -p tcp -d 10.0.1.40 --dport 5432 -j MASQUERADE 2>/dev/null; then
    echo "  ✓ POSTROUTING (MASQUERADE) configurado"
else
    echo "  ⚠ POSTROUTING pode ter falhado"
fi

# FORWARD: Permitir tráfego forwarded para o database
if iptables -A FORWARD -p tcp -d 10.0.1.40 --dport 5432 -j ACCEPT 2>/dev/null; then
    echo "  ✓ FORWARD (inbound) configurado"
fi

if iptables -A FORWARD -p tcp -s 10.0.1.40 --sport 5432 -j ACCEPT 2>/dev/null; then
    echo "  ✓ FORWARD (outbound) configurado"
fi

# LOG: Registrar conexões ao PostgreSQL (para evidência)
if iptables -A FORWARD -p tcp --dport 5432 -j LOG --log-prefix "[FW-DB] " --log-level 4 2>/dev/null; then
    echo "  ✓ LOG configurado"
else
    echo "  ⚠ LOG pode não funcionar (não crítico)"
fi

echo ""
echo "✓ Port forwarding configurado:"
echo "  Cliente → Firewall:5432 → Database:5432"
echo ""

# Mostrar regras (não-fatal se falhar)
if iptables -t nat -L -n -v >/dev/null 2>&1; then
    echo "Regras NAT ativas:"
    iptables -t nat -L PREROUTING -n -v 2>/dev/null | head -10 || true
    echo ""
fi

if iptables -L FORWARD -n -v >/dev/null 2>&1; then
    echo "Regras FORWARD ativas:"
    iptables -L FORWARD -n -v 2>/dev/null | head -10 || true
fi

echo ""
echo "Setup concluído!"
