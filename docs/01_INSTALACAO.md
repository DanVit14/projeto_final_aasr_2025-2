# Instalação e Execução do Projeto

## 📋 Pré-requisitos

- **Docker** (versão 20.10+)
- **Docker Compose** (versão 2.0+)
- **Git**
- **Sistema Operacional:** Linux (testado em Ubuntu/Debian)

---

## 🚀 Instalação Rápida

### 1. Clonar Repositório

```bash
git clone <url-do-repositorio>
cd projeto_final_aasr_2025-2
```

### 2. Verificar Docker

```bash
# Verificar versão do Docker
docker --version

# Verificar versão do Docker Compose
docker-compose --version

# Testar Docker (deve rodar sem sudo)
docker ps
```

**Se precisar de permissões:**
```bash
sudo usermod -aG docker $USER
# Fazer logout e login novamente
```

### 3. Build dos Containers

```bash
# Build de todos os serviços
docker-compose build

# Tempo estimado: 5-10 minutos (primeira vez)
```

### 4. Iniciar Serviços

```bash
# Iniciar todos os containers
docker-compose up -d

# Verificar status
docker-compose ps
```

**Esperado:** Todos os containers com status "Up"

### 5. Aguardar Inicialização

Os serviços levam tempo para inicializar completamente:

- **LDAP:** ~10 segundos
- **Firewall:** ~5 segundos
- **SMTP:** ~20 segundos
- **Database:** ~5 segundos
- **Logs-NTP:** ~5 segundos
- **Cliente:** Instantâneo

```bash
# Aguardar 30 segundos
sleep 30

# Verificar logs
docker-compose logs
```

---

## ✅ Validação da Instalação

### Teste Rápido

```bash
# Executar teste de serviços básicos
./scripts/test_services.sh
```

**Esperado:** Todos os serviços respondendo

### Teste Completo (End-to-End)

```bash
# Executar teste de integração completo
./scripts/test_end_to_end.sh
```

**Esperado:** 6/6 serviços integrados

---

## 📊 Estrutura dos Containers

| Container | IP | Portas | Status Esperado |
|-----------|-------|--------|-----------------|
| firewall | 10.0.1.20 | 2222:22 | Up |
| ldap | 10.0.1.30 | 389, 636 | Up |
| smtp | 10.0.1.30 | 2525:25 | Up |
| database | 10.0.1.40 | 5432 | Up |
| logs-ntp | 10.0.1.50 | 123/udp, 514/udp | Up |
| cliente | 10.0.1.60 | - | Up |

---

## 🛠️ Comandos Úteis

### Gerenciar Containers

```bash
# Ver status
docker-compose ps

# Ver logs
docker-compose logs [serviço]
docker-compose logs -f smtp  # Follow

# Parar todos
docker-compose stop

# Iniciar todos
docker-compose start

# Reiniciar um serviço
docker-compose restart smtp

# Parar e remover
docker-compose down

# Rebuild específico
docker-compose build smtp
docker-compose up -d smtp
```

### Acessar Containers

```bash
# Entrar no container
docker-compose exec [serviço] bash

# Exemplos
docker-compose exec smtp bash
docker-compose exec database bash
docker-compose exec cliente bash
```

### Ver Logs Específicos

```bash
# Logs do SMTP
docker-compose logs smtp

# Logs do LDAP
docker-compose logs ldap

# Últimas 50 linhas
docker-compose logs --tail=50 smtp
```

---

## 🔧 Troubleshooting

### Container Não Inicia

```bash
# Ver logs de erro
docker-compose logs [serviço]

# Rebuild forçado
docker-compose stop [serviço]
docker-compose rm -f [serviço]
docker-compose build --no-cache [serviço]
docker-compose up -d [serviço]
```

### Firewall em Loop de Restart

```bash
# Seguir guia específico
./scripts/debug_firewall.sh

# Ou aplicar correção
git pull origin main
docker-compose stop firewall
docker-compose rm -f firewall
docker-compose build firewall
docker-compose up -d firewall
```

### Logs Não Centralizam

```bash
# Diagnosticar
./scripts/diagnose_rsyslog.sh

# Corrigir
./scripts/fix_rsyslog.sh
```

### Porta em Uso

```bash
# Verificar portas em uso
sudo netstat -tlnp | grep 5432

# Alterar porta no docker-compose.yml
# Exemplo: "5433:5432" em vez de "5432:5432"
```

### Permissões Negadas

```bash
# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# Fazer logout e login novamente
```

---

## 🧹 Limpeza Completa

### Remover Tudo (Cuidado!)

```bash
# Parar e remover containers
docker-compose down

# Remover volumes (apaga dados!)
docker-compose down -v

# Remover imagens
docker-compose down --rmi all

# Limpeza geral do Docker
docker system prune -a --volumes
```

### Reiniciar do Zero

```bash
# 1. Limpar completamente
docker-compose down -v

# 2. Rebuild
docker-compose build --no-cache

# 3. Iniciar
docker-compose up -d

# 4. Aguardar e testar
sleep 30
./scripts/test_services.sh
```

---

## 📚 Próximos Passos

Após instalação bem-sucedida:

1. **Ler a topologia:** `docs/02_TOPOLOGIA.md`
2. **Entender cada serviço:** `docs/servicos/*.md`
3. **Executar teste E2E:** `docs/03_TESTE_E2E.md`
4. **Coletar evidências:** `docs/EVIDENCIAS/README.md`

---

## 🔗 Referências Úteis

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Samba AD DC](https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller)
- [Postfix Documentation](http://www.postfix.org/documentation.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

**Instalação concluída! Sistema pronto para uso.** ✅
