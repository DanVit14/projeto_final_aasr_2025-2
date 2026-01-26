# Guia: Como Transferir Arquivos para VM VirtualBox

## Problema
Não é possível copiar/colar entre o host e a VM do VirtualBox.

## Soluções Recomendadas (em ordem de preferência)

---

## Solução 1: Git (RECOMENDADA) ⭐

**Por que usar:** O projeto já precisa ser versionado em Git, então é a solução mais natural.

### No Host (seu computador):
```bash
# 1. Criar repositório local
cd /home/daniel/aasr/git
git init
git add .
git commit -m "Estrutura inicial do projeto"

# 2. Criar repositório no GitHub/GitLab (ou usar servidor Git local)
# Opção A: GitHub (mais fácil)
# - Criar repositório no GitHub
# - Fazer push:
git remote add origin https://github.com/seu-usuario/projeto_final_aasr.git
git branch -M main
git push -u origin main

# Opção B: Servidor Git local (se tiver outro computador na rede)
# - Instalar git-daemon ou usar SSH
```

### Na VM (Debian 12):
```bash
# 1. Instalar Git
sudo apt update
sudo apt install -y git

# 2. Clonar o repositório
cd ~
git clone https://github.com/seu-usuario/projeto_final_aasr.git
# OU se usar SSH:
# git clone git@github.com:seu-usuario/projeto_final_aasr.git

# 3. Trabalhar no projeto
cd projeto_final_aasr

# 4. Quando fizer alterações, commitar e fazer push
git add .
git commit -m "Descrição das mudanças"
git push

# 5. No host, fazer pull para ver as mudanças
```

**Vantagens:**
- ✅ Versionamento automático
- ✅ Histórico de mudanças
- ✅ Backup automático
- ✅ Funciona de qualquer lugar
- ✅ Não precisa configurar nada no VirtualBox

**Desvantagens:**
- ⚠️ Precisa de internet (ou servidor Git local)

---

## Solução 2: Compartilhamento de Pastas do VirtualBox 🔄

**Por que usar:** Mais rápido para desenvolvimento, sincronização automática.

### Configuração:

1. **No VirtualBox (com a VM desligada):**
   - Selecione a VM
   - Settings → Shared Folders
   - Clique no ícone "+" (Add Shared Folder)
   - Folder Path: `/home/daniel/aasr/git` (caminho no host)
   - Folder Name: `projeto_aasr` (nome que aparecerá na VM)
   - Marque "Auto-mount" e "Make Permanent"
   - OK

2. **Na VM (Debian 12):**
```bash
# 1. Instalar Guest Additions (se ainda não tiver)
sudo apt update
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
# No menu do VirtualBox: Devices → Insert Guest Additions CD Image
sudo mount /dev/cdrom /mnt
cd /mnt
sudo ./VBoxLinuxAdditions.run
sudo reboot

# 2. Adicionar usuário ao grupo vboxsf
sudo usermod -aG vboxsf $USER
# Fazer logout e login novamente (ou reiniciar)

# 3. Acessar a pasta compartilhada
cd /media/sf_projeto_aasr
# OU
ls /media/sf_*

# 4. Criar link simbólico para facilitar acesso
ln -s /media/sf_projeto_aasr ~/projeto_aasr
cd ~/projeto_aasr
```

**Vantagens:**
- ✅ Sincronização automática
- ✅ Não precisa fazer push/pull
- ✅ Funciona offline
- ✅ Muito rápido

**Desvantagens:**
- ⚠️ Precisa instalar Guest Additions
- ⚠️ Pode ter problemas de permissões
- ⚠️ Não é ideal para Git (pode causar conflitos)

---

## Solução 3: SCP/SFTP (via SSH) 📡

**Por que usar:** Transferência segura, funciona bem para arquivos individuais.

### Configuração:

1. **Na VM (Debian 12):**
```bash
# 1. Instalar e configurar SSH
sudo apt update
sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh

# 2. Descobrir IP da VM
ip addr show
# Anote o IP (ex: 192.168.56.101)

# 3. Configurar firewall (se necessário)
sudo ufw allow 22/tcp
```

2. **No Host:**
```bash
# 1. Copiar arquivos para a VM
scp -r /home/daniel/aasr/git/* usuario@192.168.56.101:~/projeto_aasr/

# 2. Ou usar SFTP (mais interativo)
sftp usuario@192.168.56.101
# Dentro do sftp:
put -r /home/daniel/aasr/git/* ~/projeto_aasr/
exit

# 3. Ou usar rsync (melhor para sincronização)
rsync -avz /home/daniel/aasr/git/ usuario@192.168.56.101:~/projeto_aasr/
```

**Vantagens:**
- ✅ Seguro (criptografado)
- ✅ Funciona bem para transferências pontuais
- ✅ Não precisa configurar VirtualBox

**Desvantagens:**
- ⚠️ Precisa fazer manualmente a cada vez
- ⚠️ Mais lento que compartilhamento de pastas

---

## Solução 4: Servidor HTTP Simples 🌐

**Por que usar:** Útil para baixar arquivos específicos rapidamente.

### No Host:
```bash
# 1. Instalar Python (geralmente já vem instalado)
cd /home/daniel/aasr/git

# 2. Criar servidor HTTP simples
python3 -m http.server 8000
# OU
python -m SimpleHTTPServer 8000  # Python 2
```

### Na VM:
```bash
# 1. Descobrir IP do host
# No host, executar: ip addr show
# Anotar o IP da interface que conecta com a VM (ex: 192.168.56.1)

# 2. Baixar arquivos
wget http://192.168.56.1:8000/arquivo.txt
# OU baixar tudo:
wget -r http://192.168.56.1:8000/
```

**Vantagens:**
- ✅ Muito simples
- ✅ Não precisa instalar nada extra

**Desvantagens:**
- ⚠️ Precisa manter o servidor rodando
- ⚠️ Não é ideal para muitos arquivos

---

## Solução 5: Pendrive Virtual (ISO) 💾

**Por que usar:** Último recurso, funciona offline.

### No Host:
```bash
# 1. Criar ISO com os arquivos
cd /home/daniel/aasr/git
mkisofs -o projeto_aasr.iso .

# 2. No VirtualBox:
# - Settings → Storage
# - Adicionar novo disco óptico
# - Selecionar o arquivo projeto_aasr.iso
```

### Na VM:
```bash
# 1. Montar o CD
sudo mount /dev/cdrom /mnt

# 2. Copiar arquivos
cp -r /mnt/* ~/projeto_aasr/

# 3. Desmontar
sudo umount /mnt
```

**Vantagens:**
- ✅ Funciona offline
- ✅ Simples

**Desvantagens:**
- ⚠️ Precisa recriar ISO a cada mudança
- ⚠️ Trabalhoso

---

## Recomendação Final 🎯

### Para Desenvolvimento Ativo:
**Use Solução 1 (Git) + Solução 2 (Compartilhamento de Pastas)**

**Workflow sugerido:**

1. **Configurar Git no host:**
   ```bash
   cd /home/daniel/aasr/git
   git init
   git remote add origin https://github.com/seu-usuario/projeto_aasr.git
   ```

2. **Configurar compartilhamento de pastas no VirtualBox**

3. **Na VM, trabalhar na pasta compartilhada:**
   ```bash
   cd /media/sf_projeto_aasr
   # Fazer alterações aqui
   ```

4. **No host, commitar e fazer push:**
   ```bash
   cd /home/daniel/aasr/git
   git add .
   git commit -m "Mudanças feitas na VM"
   git push
   ```

5. **Para sincronizar mudanças do host para VM:**
   - As mudanças aparecem automaticamente na pasta compartilhada
   - Ou fazer `git pull` na VM

### Para Apresentação:
- Ter tudo versionado no Git garante que você pode acessar de qualquer lugar
- Ter backups automáticos
- Poder mostrar o histórico de desenvolvimento

---

## Script de Ajuda para VM

Criar um script na VM para facilitar:

```bash
# ~/sync_projeto.sh
#!/bin/bash
cd /media/sf_projeto_aasr
git status
echo "Deseja fazer commit e push? (s/n)"
read resposta
if [ "$resposta" = "s" ]; then
    git add .
    echo "Digite a mensagem do commit:"
    read mensagem
    git commit -m "$mensagem"
    git push
    echo "Arquivos sincronizados!"
fi
```

Tornar executável:
```bash
chmod +x ~/sync_projeto.sh
```

---

## Troubleshooting

### Problema: Permissões na pasta compartilhada
```bash
# Adicionar usuário ao grupo vboxsf
sudo usermod -aG vboxsf $USER
# Fazer logout/login
```

### Problema: Guest Additions não funciona
```bash
# Reinstalar
sudo apt install --reinstall virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11
sudo reboot
```

### Problema: Git não funciona na VM
```bash
# Instalar Git
sudo apt update
sudo apt install -y git

# Configurar Git
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"
```

### Problema: Não consegue fazer push no Git
```bash
# Verificar conexão
ping github.com

# Se usar SSH, verificar chaves
ssh -T git@github.com

# Se usar HTTPS, pode precisar de token
# GitHub → Settings → Developer settings → Personal access tokens
```

---

## Checklist Rápido

- [ ] Escolher método de transferência (recomendo Git + Compartilhamento)
- [ ] Configurar Git no host
- [ ] Criar repositório no GitHub/GitLab
- [ ] Configurar compartilhamento de pastas no VirtualBox
- [ ] Instalar Guest Additions na VM
- [ ] Instalar Git na VM
- [ ] Testar transferência de arquivos
- [ ] Configurar workflow de trabalho

---

**Qual método você prefere usar? Posso ajudar a configurar!** 🚀
