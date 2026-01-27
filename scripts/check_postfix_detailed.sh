#!/bin/bash
# Verificação detalhada do Postfix

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=========================================="
echo "Verificação Detalhada do Postfix"
echo "=========================================="
echo ""

echo "1. Status do Postfix:"
docker-compose exec -T smtp postfix status
echo ""

echo "2. Processos do Postfix (master, smtpd):"
docker-compose exec -T smtp ps aux | grep -E "(master|smtpd)" | grep -v grep
echo ""

echo "3. Portas a escutar (25, 587):"
docker-compose exec -T smtp ss -tlnp | grep -E ":(25|587)" || echo "Nenhuma porta SMTP a escutar!"
echo ""

echo "4. Configuração inet_interfaces no main.cf:"
docker-compose exec -T smtp postconf inet_interfaces
echo ""

echo "5. Configuração mynetworks no main.cf:"
docker-compose exec -T smtp postconf mynetworks
echo ""

echo "6. Últimas 30 linhas do mail.log:"
docker-compose exec -T smtp tail -30 /var/log/mail.log 2>/dev/null || echo "mail.log vazio ou inexistente"
echo ""

echo "7. Testar conexão TCP à porta 25 no localhost (dentro do SMTP):"
docker-compose exec -T smtp bash -c "timeout 5 bash -c 'cat < /dev/null > /dev/tcp/127.0.0.1/25' && echo 'Porta 25 TCP OK'" || echo "Porta 25 TCP não responde"
echo ""

echo "8. Testar banner 220 no localhost (dentro do SMTP):"
docker-compose exec -T smtp bash -c "echo 'QUIT' | timeout 8 nc -w 5 127.0.0.1 25 2>&1" | head -10
echo ""

echo "=========================================="
