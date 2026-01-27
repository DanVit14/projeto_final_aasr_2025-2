# Problema: Postfix não consegue conectar ao LDAP

## Situação Atual

- ✅ **Conectividade TCP funciona**: `nc -zv ldap 636` conecta com sucesso
- ✅ **ldapsearch funciona**: `ldapsearch` consegue consultar o LDAP
- ❌ **postmap falha**: `postmap` retorna "Can't contact LDAP server (-1)"

## O que foi tentado

1. ✅ LDAPS direto (porta 636) - **Falha**
2. ✅ StartTLS (porta 389) - **Falha** (já tentado anteriormente)
3. ✅ Configuração `TLS_REQCERT never` em `/etc/ldap/ldap.conf` - **Não resolve**
4. ✅ Variáveis de ambiente `LDAPTLS_REQCERT=never` - **Não resolve**
5. ✅ Remoção de `bind_timeout` (parâmetro não suportado) - **Não resolve**
6. ✅ Configuração `tls_require_cert = no` - **Não resolve**
7. ✅ Teste com IP direto (10.0.1.10) - **Falha da mesma forma**

## Diagnóstico

O problema parece ser específico de como o Postfix usa a biblioteca LDAP. Mesmo com:
- Conectividade de rede funcionando
- `ldapsearch` funcionando no mesmo container
- Configurações de certificado corretas

O `postmap` (e consequentemente o Postfix) não consegue estabelecer conexão LDAP.

## Possíveis causas

1. **Bug/limitação do Postfix** com LDAP em containers Docker
2. **Problema de inicialização SSL/TLS** no contexto do Postfix
3. **Biblioteca LDAP diferente** usada pelo Postfix vs `ldapsearch`
4. **Problema de contexto/namespace** quando o Postfix executa

## Soluções alternativas

### Opção 1: Script wrapper (recomendado para continuar o projeto)

Criar um script que faz a consulta LDAP e retorna o resultado no formato esperado pelo Postfix.

### Opção 2: Proxy LDAP local

Usar um proxy LDAP local que o Postfix consegue acessar.

### Opção 3: Documentar como limitação conhecida

Documentar o problema e focar em outras partes do projeto que funcionam (SMTP básico, antivírus, etc).

## Próximos passos

1. Executar `./scripts/test_postfix_ldap_alternative.sh` para verificar versões e dependências
2. Decidir se vamos implementar solução alternativa ou documentar como limitação
3. Focar em outras funcionalidades do projeto enquanto isso
