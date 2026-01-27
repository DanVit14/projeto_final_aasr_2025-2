#!/bin/bash
# Teste CRUD no PostgreSQL (usuarios, produtos, vendas)

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

echo "=== Teste CRUD - empresa_db ==="
echo ""

run_sql() {
    docker-compose exec -T database psql -U app_user -d empresa_db -v ON_ERROR_STOP=1 "$@"
}

echo "1. READ (usuarios):"
run_sql -c "SELECT id, nome, email FROM usuarios;"
echo ""

echo "2. READ (produtos):"
run_sql -c "SELECT id, nome, preco, estoque FROM produtos;"
echo ""

echo "3. CREATE (insert teste):"
run_sql -c "INSERT INTO produtos (nome, preco, estoque) VALUES ('Produto Teste', 1.00, 1) ON CONFLICT DO NOTHING RETURNING id, nome;"
echo ""

echo "4. UPDATE:"
run_sql -c "UPDATE produtos SET estoque = estoque + 1 WHERE nome = 'Produto Teste' RETURNING id, nome, estoque;"
echo ""

echo "5. DELETE (limpar teste):"
run_sql -c "DELETE FROM produtos WHERE nome = 'Produto Teste' RETURNING id;"
echo ""

echo "=== CRUD OK ==="
