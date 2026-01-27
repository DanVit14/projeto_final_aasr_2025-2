#!/bin/bash
# Script para testar envio de e-mail

set +e

echo "=========================================="
echo "Testando Envio de E-mail"
echo "=========================================="
echo ""

# 1. Verificar se os usuários têm atributo mail
echo "1. Verificando atributos de e-mail dos usuários:"
docker-compose exec ldap ldapsearch -x -H ldaps://localhost:636 -b "dc=empresa,dc=local" -D "cn=Administrator,cn=Users,dc=empresa,dc=local" -w "Admin@123" "(mail=*)" mail 2>&1 | grep "mail:" | head -5
echo ""

# 2. Criar diretório Maildir para o usuário
echo "2. Criando diretório Maildir para user1:"
docker-compose exec smtp bash -c "mkdir -p /var/mail/vhosts/empresa.local/user1/Maildir/{new,cur,tmp} && chown -R postfix:postfix /var/mail/vhosts/empresa.local/user1"
echo "   ✓ Diretório criado"
echo ""

# 3. Testar envio usando sendmail (não precisa de TTY)
echo "3. Enviando e-mail de teste usando sendmail:"
docker-compose exec -T smtp bash -c 'echo -e "Subject: Teste de E-mail\n\nEste é um e-mail de teste do Postfix." | /usr/sbin/sendmail -v user1@empresa.local 2>&1' | head -10
echo ""

# 4. Verificar se o e-mail foi entregue
echo "4. Verificando se o e-mail foi entregue:"
if docker-compose exec smtp test -f /var/mail/vhosts/empresa.local/user1/Maildir/new/* 2>/dev/null; then
    echo -e "\033[0;32m✓ E-mail entregue!\033[0m"
    docker-compose exec smtp ls -lh /var/mail/vhosts/empresa.local/user1/Maildir/new/ | head -3
else
    echo -e "\033[1;33m⚠ E-mail não encontrado em Maildir/new\033[0m"
    echo "   Verificando Maildir/cur..."
    docker-compose exec smtp ls -lh /var/mail/vhosts/empresa.local/user1/Maildir/cur/ 2>/dev/null | head -3 || echo "   Nenhum e-mail encontrado"
fi
echo ""

# 5. Verificar logs do Postfix
echo "5. Últimas linhas dos logs relacionados ao envio:"
docker-compose logs --tail=20 smtp 2>&1 | grep -iE "sendmail|user1|delivered|sent" | tail -5 || echo "   Nenhum log relevante encontrado"
echo ""

echo "=========================================="
echo "Teste concluído!"
echo "=========================================="
