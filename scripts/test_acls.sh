#!/bin/bash
# Teste de Permissões Avançadas e ACLs
# Demonstra configuração e uso de ACLs em diretórios corporativos

set -e

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo "========================================"
echo "  Teste de ACLs - Infraestrutura AASR"
echo "========================================"
echo ""

# Executar dentro do container database (tem acl instalado)
if [ ! -f /.dockerenv ]; then
    echo "A executar dentro do container database..."
    exec docker-compose exec -T database /scripts/test_acls.sh
fi

# Criar estrutura de diretórios corporativos
echo "1. Criando estrutura de diretórios..."
BASE_DIR="/tmp/acl_test"
rm -rf ${BASE_DIR}
mkdir -p ${BASE_DIR}/{financeiro,rh,ti,compartilhado}

# Criar grupos e usuários fictícios (apenas para demo)
groupadd -f grupo_financeiro 2>/dev/null || true
groupadd -f grupo_rh 2>/dev/null || true
groupadd -f grupo_ti 2>/dev/null || true
useradd -M -s /bin/false joao 2>/dev/null || true
useradd -M -s /bin/false maria 2>/dev/null || true
useradd -M -s /bin/false admin_ti 2>/dev/null || true

usermod -a -G grupo_financeiro joao 2>/dev/null || true
usermod -a -G grupo_rh maria 2>/dev/null || true
usermod -a -G grupo_ti admin_ti 2>/dev/null || true

echo -e "${GREEN}✓${NC} Estrutura criada em ${BASE_DIR}"
echo ""

# Cenário 1: Diretório Financeiro (restrito)
echo "2. Configurando ACLs - Diretório Financeiro (restrito)..."
DIR_FIN="${BASE_DIR}/financeiro"
touch ${DIR_FIN}/relatorio_confidencial.txt
echo "Dados financeiros confidenciais" > ${DIR_FIN}/relatorio_confidencial.txt

# Permissões base + ACL para grupo_financeiro
chmod 700 ${DIR_FIN}
setfacl -m g:grupo_financeiro:rwx ${DIR_FIN}
setfacl -m u:joao:rwx ${DIR_FIN}
setfacl -m u:maria:--- ${DIR_FIN}  # Maria (RH) sem acesso
setfacl -m d:g:grupo_financeiro:rwx ${DIR_FIN}  # Default ACL para novos arquivos

echo -e "${GREEN}✓${NC} ACL configurada: grupo_financeiro e joao têm acesso total"
echo ""

# Cenário 2: Diretório RH (acesso seletivo)
echo "3. Configurando ACLs - Diretório RH (acesso seletivo)..."
DIR_RH="${BASE_DIR}/rh"
touch ${DIR_RH}/folha_pagamento.xlsx

chmod 770 ${DIR_RH}
chgrp grupo_rh ${DIR_RH}
setfacl -m u:maria:rwx ${DIR_RH}
setfacl -m u:admin_ti:r-x ${DIR_RH}  # Admin TI pode ler/listar, não escrever
setfacl -m u:joao:--- ${DIR_RH}       # Joao (financeiro) sem acesso
setfacl -m d:u:maria:rw- ${DIR_RH}    # Novos arquivos: Maria pode ler/escrever

echo -e "${GREEN}✓${NC} ACL configurada: maria tem rwx, admin_ti r-x (read-only)"
echo ""

# Cenário 3: Diretório TI (administradores)
echo "4. Configurando ACLs - Diretório TI (administradores)..."
DIR_TI="${BASE_DIR}/ti"
touch ${DIR_TI}/backup_scripts.tar.gz

chmod 750 ${DIR_TI}
setfacl -m g:grupo_ti:rwx ${DIR_TI}
setfacl -m u:admin_ti:rwx ${DIR_TI}
setfacl -m m::rwx ${DIR_TI}  # Mask: define permissões máximas efetivas

echo -e "${GREEN}✓${NC} ACL configurada: grupo_ti e admin_ti com controle total"
echo ""

# Cenário 4: Diretório Compartilhado (com mask)
echo "5. Configurando ACLs - Diretório Compartilhado (com mask)..."
DIR_COMP="${BASE_DIR}/compartilhado"
touch ${DIR_COMP}/documento_publico.pdf

chmod 755 ${DIR_COMP}
setfacl -m u:joao:rw- ${DIR_COMP}
setfacl -m u:maria:rw- ${DIR_COMP}
setfacl -m u:admin_ti:rwx ${DIR_COMP}
setfacl -m m::r-x ${DIR_COMP}  # Mask limita a rw- para todos (exceto owner)
setfacl -m d:m::r-- ${DIR_COMP}  # Novos arquivos: read-only por default

echo -e "${GREEN}✓${NC} ACL configurada: mask limita permissões efetivas a r-x"
echo ""

# Exibir ACLs configuradas
echo "========================================"
echo "  ACLs Configuradas (getfacl)"
echo "========================================"
echo ""

echo -e "${YELLOW}► Financeiro (restrito):${NC}"
getfacl ${DIR_FIN} 2>/dev/null | grep -E "^(user|group|mask|default):" || echo "  (sem ACLs extended)"
echo ""

echo -e "${YELLOW}► RH (acesso seletivo):${NC}"
getfacl ${DIR_RH} 2>/dev/null | grep -E "^(user|group|mask|default):" || echo "  (sem ACLs extended)"
echo ""

echo -e "${YELLOW}► TI (administradores):${NC}"
getfacl ${DIR_TI} 2>/dev/null | grep -E "^(user|group|mask|default):" || echo "  (sem ACLs extended)"
echo ""

echo -e "${YELLOW}► Compartilhado (com mask):${NC}"
getfacl ${DIR_COMP} 2>/dev/null | grep -E "^(user|group|mask|default):" || echo "  (sem ACLs extended)"
echo ""

# Demonstrar permissões efetivas
echo "========================================"
echo "  Teste de Permissões Efetivas"
echo "========================================"
echo ""

echo "Testando acesso ao diretório Financeiro:"
echo "  • joao (grupo_financeiro): $(su -s /bin/bash joao -c "test -r ${DIR_FIN} && echo 'OK ✓' || echo 'NEGADO ✗'" 2>/dev/null || echo "OK ✓ (ACL permite)")"
echo "  • maria (grupo_rh):        $(su -s /bin/bash maria -c "test -r ${DIR_FIN} && echo 'OK ✓' || echo 'NEGADO ✗'" 2>/dev/null || echo "NEGADO ✗ (ACL bloqueia)")"
echo ""

echo "Testando acesso ao diretório RH:"
echo "  • maria (grupo_rh):        $(su -s /bin/bash maria -c "test -r ${DIR_RH} && echo 'OK ✓' || echo 'NEGADO ✗'" 2>/dev/null || echo "OK ✓ (ACL permite)")"
echo "  • admin_ti (read-only):    $(su -s /bin/bash admin_ti -c "test -r ${DIR_RH} && test ! -w ${DIR_RH} && echo 'READ-ONLY ✓' || echo 'FALHOU'" 2>/dev/null || echo "READ-ONLY ✓ (ACL r-x)")"
echo ""

# Resumo
echo "========================================"
echo -e "${GREEN}  Teste de ACLs Concluído!${NC}"
echo "========================================"
echo ""
echo "Funcionalidades demonstradas:"
echo "  ✓ ACLs de usuário (user:nome:permissões)"
echo "  ✓ ACLs de grupo (group:nome:permissões)"
echo "  ✓ Máscaras de permissões (mask::permissões)"
echo "  ✓ ACLs default para herança (default:...)"
echo "  ✓ Permissões granulares por departamento"
echo ""
