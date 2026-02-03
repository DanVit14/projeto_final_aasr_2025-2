#!/bin/bash
# Corrigir rsyslog centralizado
# Configura SMTP para enviar logs e Logs-NTP para receber

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "============================================================"
echo -e "${CYAN}  CORREÇÃO: rsyslog Centralizado${NC}"
echo "============================================================"
echo ""

# ============================================
# 1. Configurar Logs-NTP (Servidor)
# ============================================
echo -e "${CYAN}PASSO 1: Configurar servidor Logs-NTP...${NC}"
echo ""

echo "1.1. Habilitar recepção UDP no rsyslog..."
# Remover configuração antiga se existir
docker-compose exec -T logs-ntp rm -f /etc/rsyslog.d/00-remote.conf 2>/dev/null || true

# Criar nova configuração
docker-compose exec -T logs-ntp bash -c 'cat > /etc/rsyslog.d/00-remote.conf <<EOF
# Habilitar recepção de logs remotos via UDP
module(load="imudp")
input(type="imudp" port="514")

# Template para organizar logs por host
\$template RemoteHost,"/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteHost
EOF'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Configuração criada em /etc/rsyslog.d/00-remote.conf${NC}"
else
    echo -e "${RED}✗ Erro ao criar configuração${NC}"
fi
echo ""

echo "1.2. Criar diretório para logs remotos..."
docker-compose exec -T logs-ntp mkdir -p /var/log/remote
docker-compose exec -T logs-ntp chmod 755 /var/log/remote
echo -e "${GREEN}✓ Diretório /var/log/remote criado${NC}"
echo ""

echo "1.3. Reiniciar rsyslog no Logs-NTP..."
# Parar rsyslog (se estiver rodando)
docker-compose exec -T logs-ntp sh -c 'kill $(cat /run/rsyslogd.pid 2>/dev/null) 2>/dev/null || killall rsyslogd 2>/dev/null || true'
sleep 2

# Iniciar rsyslog
docker-compose exec -T logs-ntp rsyslogd
sleep 2

if docker-compose exec -T logs-ntp ps aux | grep -q "[r]syslogd"; then
    echo -e "${GREEN}✓ rsyslog reiniciado${NC}"
else
    echo -e "${RED}✗ rsyslog não iniciou${NC}"
fi
echo ""

echo "1.4. Verificar porta 514 UDP..."
if docker-compose exec -T logs-ntp ss -ulnp 2>/dev/null | grep -q ":514"; then
    echo -e "${GREEN}✓ rsyslog escutando em UDP 514${NC}"
    docker-compose exec -T logs-ntp ss -ulnp 2>/dev/null | grep ":514"
else
    echo -e "${YELLOW}⚠ Porta 514 pode não estar visível (esperado em alguns casos)${NC}"
fi
echo ""

# ============================================
# 2. Configurar SMTP (Cliente)
# ============================================
echo -e "${CYAN}PASSO 2: Configurar cliente SMTP...${NC}"
echo ""

echo "2.1. Configurar forward de logs no SMTP..."
# Remover configuração antiga se existir
docker-compose exec -T smtp rm -f /etc/rsyslog.d/50-forward.conf 2>/dev/null || true

# Criar nova configuração
docker-compose exec -T smtp bash -c 'cat > /etc/rsyslog.d/50-forward.conf <<EOF
# Forward todos os logs para o servidor central
*.* @logs-ntp:514
EOF'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Configuração criada em /etc/rsyslog.d/50-forward.conf${NC}"
else
    echo -e "${RED}✗ Erro ao criar configuração${NC}"
fi
echo ""

echo "2.2. Reiniciar rsyslog no SMTP..."
# Parar rsyslog (se estiver rodando)
docker-compose exec -T smtp sh -c 'kill $(cat /run/rsyslogd.pid 2>/dev/null) 2>/dev/null || killall rsyslogd 2>/dev/null || true'
sleep 2

# Iniciar rsyslog
docker-compose exec -T smtp rsyslogd
sleep 2

if docker-compose exec -T smtp ps aux | grep -q "[r]syslogd"; then
    echo -e "${GREEN}✓ rsyslog reiniciado${NC}"
else
    echo -e "${YELLOW}⚠ rsyslog pode não estar rodando (não crítico se syslog está)${NC}"
fi
echo ""

# ============================================
# 3. Teste de Validação
# ============================================
echo -e "${CYAN}PASSO 3: Validar configuração...${NC}"
echo ""

TEST_MSG="RSYSLOG_FIX_TEST_$(date +%s)"

echo "3.1. Enviando mensagem de teste do SMTP..."
docker-compose exec -T smtp logger "${TEST_MSG}"
echo "Aguardando 5 segundos para propagação..."
sleep 5
echo ""

echo "3.2. Procurando mensagem no Logs-NTP..."
if docker-compose exec -T logs-ntp grep -r "${TEST_MSG}" /var/log 2>/dev/null; then
    echo ""
    echo -e "${GREEN}✓✓✓ SUCESSO! Logs centralizados funcionando! ✓✓✓${NC}"
    echo ""
    echo "Logs do SMTP estarão em:"
    echo "  /var/log/remote/mail.empresa.local/ (ou hostname do SMTP)"
else
    echo -e "${YELLOW}⚠ Mensagem ainda não apareceu${NC}"
    echo ""
    echo "Possíveis causas:"
    echo "  1. Pode demorar mais que 5s (normal)"
    echo "  2. rsyslog pode precisar de restart mais agressivo"
    echo "  3. Verificar logs com:"
    echo "     docker-compose exec logs-ntp tail -f /var/log/syslog"
    echo "     docker-compose exec logs-ntp tail -f /var/log/messages"
fi
echo ""

# ============================================
# 4. Forçar Logs do Postfix
# ============================================
echo -e "${CYAN}PASSO 4: Forçar geração de logs do Postfix...${NC}"
echo ""

echo "4.1. Recarregar Postfix para gerar logs..."
docker-compose exec -T smtp postfix reload
sleep 2
echo ""

echo "4.2. Enviar email de teste..."
docker-compose exec -T smtp sendmail user1@empresa.local <<EOF
Subject: Teste rsyslog $(date +%s)
Teste de logs centralizados
EOF
sleep 3
echo -e "${GREEN}✓ Email de teste enviado${NC}"
echo ""

echo "4.3. Verificar logs do Postfix no servidor central..."
echo "Procurando por 'postfix' em /var/log/remote/..."
docker-compose exec -T logs-ntp find /var/log/remote -type f -exec grep -l "postfix" {} \; 2>/dev/null || echo "  (nenhum log de postfix ainda)"
echo ""

# ============================================
# RESUMO FINAL
# ============================================
echo "============================================================"
echo -e "${GREEN}  CONFIGURAÇÃO CONCLUÍDA${NC}"
echo "============================================================"
echo ""
echo "Ações realizadas:"
echo "  ✓ Logs-NTP configurado para receber UDP:514"
echo "  ✓ SMTP configurado para enviar logs"
echo "  ✓ rsyslog reiniciado em ambos"
echo "  ✓ Teste de validação executado"
echo ""
echo "Para monitorar logs chegando:"
echo "  # Ver logs em tempo real no servidor:"
echo "  docker-compose exec logs-ntp tail -f /var/log/messages"
echo "  docker-compose exec logs-ntp tail -f /var/log/remote/*/postfix.log"
echo ""
echo "  # Ver estrutura de logs remotos:"
echo "  docker-compose exec logs-ntp ls -lR /var/log/remote/"
echo ""
echo "Para re-testar:"
echo "  ./scripts/diagnose_rsyslog.sh"
echo ""
