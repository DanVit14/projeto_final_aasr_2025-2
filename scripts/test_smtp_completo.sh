#!/bin/bash
# Teste completo do SMTP: envio + verificação de entrega

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=========================================="
echo "Teste Completo do SMTP"
echo "=========================================="
echo ""

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "1. Verificar se SMTP está a responder..."
if docker-compose exec -T smtp bash -c "echo QUIT | timeout 5 nc 127.0.0.1 25" | grep -q "220"; then
    echo -e "${GREEN}✓ SMTP a responder${NC}"
else
    echo -e "${RED}✗ SMTP não responde. Aguarde mais tempo ou verifique os logs.${NC}"
    exit 1
fi
echo ""

echo "2. Enviar e-mail de teste para user1@empresa.local..."
docker-compose exec -T smtp sendmail user1@empresa.local <<EOF
From: teste@empresa.local
To: user1@empresa.local
Subject: Teste SMTP $(date +%Y%m%d_%H%M%S)

Este é um e-mail de teste enviado em $(date).

Se recebeu esta mensagem, o SMTP está a funcionar corretamente.
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ E-mail enviado${NC}"
else
    echo -e "${RED}✗ Erro ao enviar e-mail${NC}"
    exit 1
fi
echo ""

echo "3. Aguardar 3 segundos para processamento..."
sleep 3
echo ""

echo "4. Verificar se e-mail foi entregue no Maildir de user1..."
MAIL_COUNT=$(docker-compose exec -T smtp find /var/mail/vhosts/empresa.local/user1/Maildir/new -type f 2>/dev/null | wc -l)

if [ "$MAIL_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ $MAIL_COUNT mensagem(ns) no Maildir de user1${NC}"
    echo ""
    echo "Últimas 3 mensagens:"
    docker-compose exec -T smtp ls -lht /var/mail/vhosts/empresa.local/user1/Maildir/new 2>/dev/null | head -4
else
    echo -e "${YELLOW}⚠ Nenhuma mensagem nova. Verificando pasta cur...${NC}"
    MAIL_COUNT_CUR=$(docker-compose exec -T smtp find /var/mail/vhosts/empresa.local/user1/Maildir/cur -type f 2>/dev/null | wc -l)
    if [ "$MAIL_COUNT_CUR" -gt 0 ]; then
        echo -e "${GREEN}✓ $MAIL_COUNT_CUR mensagem(ns) lida(s) em cur/${NC}"
    else
        echo -e "${RED}✗ Sem mensagens no Maildir${NC}"
    fi
fi
echo ""

echo "5. Ver últimas 10 linhas do mail.log..."
docker-compose exec -T smtp tail -10 /var/log/mail.log 2>/dev/null || echo "mail.log não disponível"
echo ""

echo "=========================================="
echo -e "${GREEN}Teste completo!${NC}"
echo ""
echo "Para ver uma mensagem:"
echo "  docker-compose exec smtp cat \$(docker-compose exec smtp find /var/mail/vhosts/empresa.local/user1/Maildir/new -type f | head -1)"
echo ""
echo "Para limpar o Maildir:"
echo "  docker-compose exec smtp rm -f /var/mail/vhosts/empresa.local/user1/Maildir/new/*"
echo "=========================================="
