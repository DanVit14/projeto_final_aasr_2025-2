# Estudo: LDAP em Ambientes de Container

## Problemas Conhecidos

### Postfix + LDAP em Containers Docker

**Problema Principal:**
Postfix frequentemente não consegue conectar ao servidor LDAP mesmo quando:
- A conectividade de rede funciona (testado com `nc`, `telnet`)
- `ldapsearch` funciona no mesmo container
- As configurações de certificado estão corretas

**Erro Típico:**
```
postmap: warning: dict_ldap_connect: Unable to bind to server ldap://ldap:636: -1 (Can't contact LDAP server)
postmap: fatal: table ldap:/etc/postfix/ldap/ldap-virtual-mailbox-maps.cf: query error: Transport endpoint is not connected
```

### Referências e Issues Conhecidos

1. **docker-mailserver/docker-mailserver#1468**
   - Problema: Postfix LDAP `%s` não resolve corretamente para email completo
   - Sintoma: `%s` é substituído apenas pelo domínio ao invés do email completo
   - Link: https://github.com/docker-mailserver/docker-mailserver/issues/1468

2. **docker-mailserver/docker-mailserver#779**
   - Problema: "Cannot connect to LDAP server"
   - Mesmo com conectividade de rede funcionando
   - Link: https://github.com/docker-mailserver/docker-mailserver/issues/779

3. **Stack Overflow: temporary lookup failure error using postfix with ldap**
   - Problema: Erros de "temporary lookup failure" com Postfix e LDAP
   - Link: https://stackoverflow.com/questions/49772730/temporary-lookup-failure-error-using-postfix-with-ldap

## Causas Prováveis

### 1. Problema de Inicialização SSL/TLS
- O Postfix pode estar tentando inicializar SSL/TLS antes que as bibliotecas estejam prontas
- Contexto de execução diferente entre `ldapsearch` (shell) e `postmap` (Postfix)

### 2. Bibliotecas LDAP Diferentes
- Postfix pode usar uma versão diferente da biblioteca LDAP
- Incompatibilidade entre versões de `libldap` usadas por diferentes ferramentas

### 3. Problema de Namespace/Contexto
- Postfix pode executar em um contexto diferente (chroot, namespace, etc)
- Acesso limitado a arquivos de configuração ou certificados

### 4. Bug do Postfix com LDAP em Containers
- Problema conhecido mas não resolvido na versão atual do Postfix
- Específico para ambientes containerizados

## Soluções Alternativas

### 1. Script Wrapper (Implementado)
- Usar lookup type `external` do Postfix
- Script externo que consulta LDAP usando `ldapsearch`
- Retorna resultado no formato esperado pelo Postfix
- **Vantagem**: Funciona independente do problema do Postfix
- **Desvantagem**: Overhead adicional de processos

### 2. Proxy LDAP Local
- Executar um proxy LDAP local no container SMTP
- Postfix conecta ao proxy local (que funciona)
- Proxy consulta o LDAP real
- **Vantagem**: Transparente para o Postfix
- **Desvantagem**: Complexidade adicional

### 3. Usar Outro Backend
- PostgreSQL ou MySQL ao invés de LDAP direto
- Script de sincronização LDAP → Database
- **Vantagem**: Mais confiável
- **Desvantagem**: Sincronização adicional necessária

### 4. Documentar como Limitação
- Aceitar que LDAP direto não funciona
- Focar em outras funcionalidades
- **Vantagem**: Não perde tempo
- **Desvantagem**: Funcionalidade incompleta

## Configuração Recomendada para LDAP em Containers

### Variáveis de Ambiente Importantes
```bash
LDAP_SERVER_HOST=ldap
LDAP_SEARCH_BASE=dc=empresa,dc=local
LDAP_BIND_DN=cn=Administrator,cn=Users,dc=empresa,dc=local
LDAP_BIND_PW=Admin@123
LDAP_START_TLS=yes  # ou usar LDAPS direto
```

### Filtros de Consulta LDAP
- `LDAP_QUERY_FILTER_DOMAIN`: Domínios para roteamento
- `LDAP_QUERY_FILTER_USER`: Caixas de correio pessoais `(mail=%s)`
- `LDAP_QUERY_FILTER_ALIAS`: Aliases pessoais
- `LDAP_QUERY_FILTER_GROUP`: Caixas de correio de grupo
- `LDAP_QUERY_FILTER_SENDERS`: Validação de remetentes

### Verificação de Conectividade
Sempre testar com `ldapsearch` antes de configurar Postfix:
```bash
ldapsearch -x -H ldaps://ldap:636 -b "dc=empresa,dc=local" \
  -D "cn=Administrator,cn=Users,dc=empresa,dc=local" \
  -w "Admin@123" -LLL "(mail=user@empresa.local)"
```

## Referências

- [Docker Mailserver - LDAP Authentication](https://docker-mailserver.github.io/docker-mailserver/v10.2/config/advanced/auth-ldap/)
- [GitHub - teid/postfix-ldap](https://github.com/teid/postfix-ldap) - Imagem Docker com Postfix e LDAP
- [Postfix LDAP Howto](http://www.postfix.org/LDAP_README.html) - Documentação oficial

## Conclusão

O problema de Postfix + LDAP em containers é **conhecido e documentado**. A solução de script wrapper é uma **workaround válida e funcional** que permite continuar o desenvolvimento enquanto o problema raiz não é resolvido.
