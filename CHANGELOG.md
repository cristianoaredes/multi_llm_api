# Registro de Alterações

Todas as alterações notáveis deste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto segue o [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [1.1.0] - 2024-06-10

### Adicionado
- Documentação detalhada sobre as medidas de segurança implementadas
- Configurações de segurança aprimoradas para a API Gemini via variáveis de ambiente
- Testes adicionais para garantir a eficácia das medidas de segurança

### Melhorado
- Otimização da ordem dos middlewares para maximizar segurança
- Sanitização de entradas mais robusta contra diferentes tipos de injeção
- Documentação expandida para configurações de segurança

## [1.0.0] - 2023-08-01

### Adicionado
- Configuração inicial do projeto
- Estrutura de diretórios feature-first
- Framework Shelf para roteamento da API
- Sistema de injeção de dependência
- Middleware de autenticação JWT
- Middleware de sanitização de entrada
- Middleware de validação de dados
- Middleware de tratamento de erros
- Middleware de logging
- Middleware de limitação de taxa
- Endpoints de autenticação (registro, login, refresh, logout)
- Endpoints de geração de texto e chat com IA
- Suporte a streaming de respostas para texto e chat
- Configurações de segurança para Gemini API
- Cache de respostas para otimização de performance
- Testes unitários e de integração
- Documentação OpenAPI/Swagger
- Configuração Docker e Docker Compose
- Suporte para múltiplos modelos de IA generativa
- Endpoint de listagem de modelos disponíveis

### Alterado
- Atualização do README com instruções detalhadas
- Migração do arquivo server_fixed.dart para server.dart unificado
- Renomeação do pacote de 'api_dart' para 'multi_llm_api'

### Corrigido
- Correção de tipo explícito em Future.delayed no OpenRouterService
- Correção de tipo explícito no parâmetro error nas funções onError 