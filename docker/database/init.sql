-- Script de inicialização do banco de dados
-- Criação de tabelas de exemplo

-- Tabela de usuários
CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de produtos
CREATE TABLE IF NOT EXISTS produtos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    preco DECIMAL(10,2) NOT NULL,
    estoque INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de vendas
CREATE TABLE IF NOT EXISTS vendas (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER REFERENCES usuarios(id),
    produto_id INTEGER REFERENCES produtos(id),
    quantidade INTEGER NOT NULL,
    valor_total DECIMAL(10,2) NOT NULL,
    data_venda TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir dados de exemplo
INSERT INTO usuarios (nome, email) VALUES
    ('Admin', 'admin@empresa.local'),
    ('Usuario 1', 'user1@empresa.local'),
    ('Usuario 2', 'user2@empresa.local')
ON CONFLICT (email) DO NOTHING;

INSERT INTO produtos (nome, preco, estoque) VALUES
    ('Produto A', 99.90, 50),
    ('Produto B', 149.90, 30),
    ('Produto C', 199.90, 20)
ON CONFLICT DO NOTHING;
