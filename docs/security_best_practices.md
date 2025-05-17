# Boas Práticas de Segurança

Este documento descreve as boas práticas de segurança adotadas e recomendadas para o projeto API Dart.

## Gerenciamento de Segredos

### Armazenamento de Chaves API e Segredos

- **Nunca** commit chaves API, senhas ou outros segredos diretamente no código fonte
- **Sempre** use variáveis de ambiente para armazenar informações sensíveis
- **Sempre** inclua arquivos `.env` no `.gitignore` para evitar que sejam acidentalmente incluídos no controle de versão
- Para arquivos de exemplo, use nomes descritivos como placeholders (ex: `YOUR_API_KEY_HERE`)

### Como Usar Corretamente

1. Copie o arquivo `.env.example` para um novo arquivo `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edite o arquivo `.env` e adicione suas credenciais reais:
   ```
   GEMINI_API_KEY=sua_chave_real_aqui
   JWT_SECRET=seu_segredo_jwt_aqui
   ```

3. O código usará as variáveis de ambiente automaticamente através da classe `EnvConfig`

## Proteção de Dados

### Sanitização de Entrada

O projeto implementa um middleware de sanitização para todas as requisições que:
- Remove caracteres potencialmente perigosos
- Escapa conteúdo HTML para prevenir XSS
- Sanitiza entradas para prevenir injeção SQL
- Processa recursivamente objetos JSON

### Validação de Dados

Todo o input do usuário é validado antes de ser processado:
- Validação estrutural através dos DTOs
- Verificação de tipos
- Limitação de tamanho de campos
- Filtragem de conteúdo impróprio através das configurações de segurança do Gemini

## Autenticação e Autorização

### JWT (JSON Web Tokens)

- Tokens possuem tempo de expiração configurável
- O segredo usado para assinar tokens é obtido de variáveis de ambiente
- Implementação de refresh tokens para melhor experiência do usuário sem comprometer a segurança

### Senhas

- Senhas são armazenadas com hash usando algoritmos seguros
- Nunca armazene senhas em texto puro
- Implemente políticas de complexidade de senha

## Configuração para Produção

Para ambientes de produção, considere as seguintes práticas adicionais:

- Use serviços de gerenciamento de segredos como AWS Secrets Manager, HashiCorp Vault ou Google Secret Manager
- Gere segredos JWT únicos para cada ambiente
- Nunca reutilize credenciais entre ambientes (desenvolvimento, teste, produção)
- Configure TLS/HTTPS para todo o tráfego usando certificados válidos
- Implemente rate limiting para prevenir abusos
- Configure logs de segurança e monitore por atividades suspeitas

## Checklist para Revisão de Segurança

Antes de implantar uma nova versão, revise os seguintes pontos:

- [ ] Nenhuma chave API ou segredo está hardcoded no código fonte
- [ ] Todos os arquivos `.env` estão incluídos no `.gitignore`
- [ ] O middleware de sanitização está ativo para todas as rotas que aceitam entrada de usuário
- [ ] Validação de dados está implementada para todos os endpoints
- [ ] As configurações de segurança do Gemini estão aplicadas conforme necessário
- [ ] Os testes de segurança foram executados e passaram
- [ ] Os logs não expõem informações sensíveis

## Relatando Problemas de Segurança

Se você encontrar uma vulnerabilidade de segurança, por favor, não a divulgue publicamente. Em vez disso:

1. Entre em contato diretamente com os mantenedores do projeto
2. Forneça detalhes suficientes para reproduzir o problema
3. Aguarde uma resposta antes de divulgar publicamente 