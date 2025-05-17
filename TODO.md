# TODO List - API Dart Example

## Fase 1: Implementação do Core (Concluída)
- [x] Configurar estrutura do projeto (Feature-First)
- [x] Definir modelo `Item`
- [x] Implementar `ItemRepository` (Interface + Implementação em Memória)
- [x] Implementar `ItemService`
- [x] Implementar `ItemHandler`
- [x] Implementar `AuthService`
- [x] Implementar `AuthHandler`
- [x] Implementar `GenerativeService` (Geração de texto básica) @phase2
- [x] Implementar `GenerativeHandler` (Geração de texto básica) @phase2
- [x] Configurar Injeção de Dependência (`get_it`)
- [x] Configurar Variáveis de Ambiente (`dotenv`)
- [x] Configurar Logging (`logging`)
- [x] Configurar Exceções Personalizadas
- [x] Configurar Middleware de Tratamento de Erros
- [x] Configurar Middleware de Autenticação
- [x] Configurar Middleware de Logging
- [x] Configurar Rotas e Pipeline (`server_setup.dart`)
- [x] Criar Ponto de Entrada do Servidor (`bin/server.dart`)
- [x] Adicionar tratamento básico de CORS
- [x] Criar `pubspec.yaml`
- [x] Criar `analysis_options.yaml` (usando `very_good_analysis`)
- [x] Criar `README.md`
- [x] Criar este `TODO.md`

## Fase 2: Melhorias e Refinamentos (Em Progresso)

### Alta Prioridade
- [x] **Integração com Banco de Dados:**
  - [x] Selecionar tecnologia de banco de dados (PostgreSQL ou SQLite) ✅ PostgreSQL
  - [x] Criar esquema de banco de dados e migrações
  - [x] Implementar repositório de banco de dados para `Item`
  - [x] Adicionar pool de conexões e tratamento de erros
  - [x] Adicionar suporte a transações para operações em múltiplas etapas

- [x] **Autenticação JWT:**
  - [x] Implementar geração e validação de tokens JWT
  - [x] Adicionar hash seguro de senha (bcrypt/argon2) ✅ SHA-256 com salt
  - [x] Criar modelo de usuário e repositório
  - [x] Implementar mecanismo de refresh de token
  - [x] Adicionar autorização baseada em funções

- [x] **Validação e Sanitização de Entrada:**
  - [x] Adicionar middleware de validação de requisições
  - [x] Implementar validação abrangente de DTOs
  - [x] Sanitizar entradas para prevenir ataques de injeção
  - [x] Adicionar tratamento de erros de validação
  - [x] Criar testes para middleware de validação e sanitização

- [x] **Padronização de Tratamento de Erros:**
  - [x] Padronizar formato de resposta de erro em todos os endpoints
  - [x] Escolher linguagem consistente (inglês ou português) ✅ Inglês
  - [x] Adicionar tipos de exceção mais específicos
  - [x] Implementar log de erros adequado com níveis de severidade

- [x] **Renomeação do Pacote:**
  - [x] Atualizar nome do pacote de 'api_dart' para 'multi_llm_api' no pubspec.yaml
  - [x] Atualizar todas as importações em arquivos .dart
  - [x] Atualizar referências em arquivos de configuração
  - [x] Atualizar o nome do banco de dados padrão e outros identificadores internos

- [x] **Expansão de Testes:**
  - [x] Escrever testes unitários para todos os serviços
  - [x] Escrever testes unitários para repositórios
  - [x] Escrever testes unitários para middleware
  - [x] Expandir testes de integração para todos os endpoints
  - [x] Adicionar relatório de cobertura de testes
  - [x] Implementar mocking para dependências externas

### Média Prioridade
- [x] **Documentação OpenAPI:**
  - [x] Completar a especificação OpenAPI com esquemas detalhados
  - [x] Documentar todos os endpoints (incluindo endpoint de chat)
  - [x] Adicionar exemplos de corpo de requisição/resposta
  - [x] Documentar respostas de erro
  - [x] Documentar requisitos de autenticação
  - [x] Implementar geração de código baseada na especificação OpenAPI

- [x] **Otimização de IA Generativa:**
  - [x] Tornar o nome do modelo Gemini configurável via `.env`
  - [x] Adicionar limitação de taxa para uso da API
  - [x] Implementar cache para solicitações comuns
  - [x] Configurar configurações de segurança para solicitações Gemini
  - [x] Implementar respostas em streaming para gerações de texto grandes
  - [ ] Adicionar suporte para entradas multimodais
  - [x] Padronizar a linguagem nas mensagens de erro

- [ ] **CORS e Segurança:**
  - [ ] Implementar tratamento adequado de CORS para produção
  - [ ] Adicionar configuração específica de origens, métodos, cabeçalhos
  - [ ] Criar middleware dedicado de CORS
  - [ ] Implementar cabeçalhos de segurança (CSP, HSTS, etc.)

- [x] **Gerenciamento de Configuração:**
  - [x] Gerenciar diferentes arquivos `.env` por ambiente (dev, prod, test)
  - [x] Extrair funções de utilidade compartilhadas para `core/utils`
  - [x] Implementar feature flags para lançamento gradual

- [ ] **Expansão de Testes de Carga:**
  - [ ] Criar cenários de teste abrangentes para todos os endpoints
  - [ ] Implementar aumento gradual de carga para encontrar pontos de quebra
  - [ ] Testar fluxo de autenticação e cenários de erro
  - [ ] Adicionar coleta e relatório de métricas de desempenho

### Baixa Prioridade
- [x] **Conteinerização e Implantação:**
  - [x] Adicionar Dockerfile para conteinerização
  - [x] Criar configuração docker-compose para desenvolvimento local
  - [x] Implementar configurações específicas de ambiente
  - [x] Documentar procedimentos de implantação

- [ ] **Pipeline de CI/CD:**
  - [ ] Configurar testes e linting automatizados
  - [ ] Implementar automação de build e implantação
  - [ ] Adicionar gerenciamento de versão e procedimentos de release

- [ ] **Monitoramento e Observabilidade:**
  - [ ] Melhorar logging com formatos estruturados
  - [ ] Adicionar coleta de métricas para monitoramento de desempenho
  - [ ] Implementar verificações de saúde e alertas
  - [ ] Configurar gerenciamento centralizado de logs

- [x] **Recursos Avançados:**
  - [x] Implementar paginação para endpoints de lista
  - [ ] Adicionar opções de filtragem e ordenação
  - [ ] Implementar cache para dados acessados frequentemente
  - [ ] Adicionar suporte a webhooks para notificações de eventos
  - [ ] Implementar processamento de tarefas em segundo plano

- [ ] **Melhorias na Injeção de Dependência:**
  - [ ] Explorar recursos avançados do `get_it` (escopos, registros assíncronos)
  - [ ] Implementar padrões de fábrica para criação de objetos complexos

## Fase 3: Melhorias Futuras (Planejadas)

### Alta Prioridade
- [ ] **Implementação de Cache:**
  - [ ] Adicionar integração com Redis para cache
  - [ ] Implementar middleware de cache para solicitações GET
  - [ ] Desenvolver estratégia de invalidação de cache

- [ ] **Limitação de Taxa:**
  - [ ] Implementar rastreamento de solicitações por IP ou chave de API
  - [ ] Definir limites configuráveis para diferentes endpoints
  - [ ] Adicionar cabeçalhos de limite de taxa às respostas

- [ ] **Versionamento de API:**
  - [ ] Adicionar cabeçalhos de versão a solicitações e respostas
  - [ ] Implementar rotas versionadas (por exemplo, /api/v2)
  - [ ] Criar estratégia de depreciação para versões antigas

### Média Prioridade
- [ ] **Suporte a GraphQL:**
  - [ ] Definir esquema GraphQL para entidades
  - [ ] Implementar resolvers usando serviços existentes
  - [ ] Adicionar endpoint GraphQL à API

- [ ] **WebSockets para Recursos em Tempo Real:**
  - [ ] Adicionar suporte a WebSocket ao servidor
  - [ ] Implementar sistema de eventos para atualizações em tempo real
  - [ ] Criar API de assinatura para clientes

- [ ] **Segurança Aprimorada:**
  - [ ] Implementar cabeçalhos de segurança
  - [ ] Adicionar suporte para chaves de API ao lado do JWT
  - [ ] Implementar proteção CSRF

### Baixa Prioridade
- [ ] **Monitoramento Avançado:**
  - [ ] Implementar rastreamento distribuído
  - [ ] Adicionar rastreamento de métricas de negócios
  - [ ] Criar dashboards personalizados para monitoramento

- [ ] **Internacionalização:**
  - [ ] Adicionar suporte para múltiplos idiomas nas respostas
  - [ ] Implementar detecção de localidade
  - [ ] Criar sistema de gerenciamento de tradução

## Instruções para Atualização desta Lista

1. Marque tarefas como completas utilizando o formato `[x]`
2. Adicione detalhes específicos sobre implementações concluídas
3. Adicione novas tarefas à medida que são identificadas
4. Ajuste as prioridades conforme necessário
5. Mantenha a lista organizada e categorizada
6. Atualize a lista regularmente para refletir o estado atual do projeto 