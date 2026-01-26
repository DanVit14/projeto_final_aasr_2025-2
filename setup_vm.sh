#!/bin/bash
# Script de setup para VM Debian 12
# Instala todas as dependências necessárias para o projeto

set -e

echo "=========================================="
echo "Setup da VM - Projeto Final AASR"
echo "=========================================="

# Atualizar sistema
echo "[1/8] Atualizando sistema..."
sudo apt update
sudo apt upgrade -y

# Instalar dependências básicas
echo "[2/8] Instalando dependências básicas..."
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    net-tools \
    iputils-ping \
    dnsutils \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common

# Instalar Docker
echo "[3/8] Instalando Docker..."
if ! command -v docker &> /dev/null; then
    # Adicionar repositório oficial do Docker
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    echo "Docker já está instalado"
fi

# Adicionar usuário ao grupo docker
echo "[4/8] Configurando permissões Docker..."
sudo usermod -aG docker $USER

# Instalar Docker Compose (standalone, se necessário)
echo "[5/8] Verificando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose já está instalado"
fi

# Instalar ferramentas adicionais úteis
echo "[6/8] Instalando ferramentas adicionais..."
sudo apt install -y \
    htop \
    tree \
    jq \
    zip \
    unzip \
    tcpdump \
    iptables \
    netfilter-persistent \
    iptables-persistent

# Configurar timezone
echo "[7/8] Configurando timezone..."
sudo timedatectl set-timezone America/Sao_Paulo

# Verificar instalações
echo "[8/8] Verificando instalações..."
echo ""
echo "=== Verificações ==="
echo "Docker version:"
docker --version 2>/dev/null || echo "Docker não encontrado (faça logout/login após adicionar ao grupo docker)"
echo ""
echo "Docker Compose version:"
docker-compose --version 2>/dev/null || docker compose version 2>/dev/null || echo "Docker Compose não encontrado"
echo ""
echo "Git version:"
git --version
echo ""
echo "Timezone:"
timedatectl | grep "Time zone"

echo ""
echo "=========================================="
echo "Setup concluído!"
echo "=========================================="
echo ""
echo "IMPORTANTE: Faça logout e login novamente"
echo "para que as permissões do Docker funcionem."
echo ""
echo "Ou execute: newgrp docker"
echo ""
echo "Depois, clone o repositório:"
echo "  git clone https://github.com/DanVit14/projeto_final_aasr_2025-2.git"
echo "  cd projeto_final_aasr_2025-2"
echo ""
