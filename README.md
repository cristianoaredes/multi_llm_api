# 🚀 API Dart

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart Version](https://img.shields.io/badge/Dart-3.0%2B-blue)](https://dart.dev)
[![Docker](https://img.shields.io/badge/Docker-Supported-blue?logo=docker)](https://www.docker.com/)

Uma API backend robusta e escalável construída com Dart e o framework Shelf. Este projeto demonstra como criar uma API backend moderna com recursos avançados como autenticação JWT, integração com IA Generativa, validação de entrada, e containerização com Docker.

![API Dart Banner](https://via.placeholder.com/1200x300/0175C2/FFFFFF?text=API+Dart)

## ✨ Recursos

- **Arquitetura feature-first** para código modular e organizado
- **Autenticação completa com JWT**
- **Integração com IA Generativa**:
  - Google Gemini API com configurações de segurança
  - Suporte opcional para OpenRouter (acesso a múltiplos modelos como OpenAI GPT, Claude)
  - Streaming de respostas em tempo real
- **Sistema de validação e sanitização** de entrada para proteger contra injeções
- **PostgreSQL** para armazenamento de dados persistente
- **Cache** para otimização de performance
- **Documentação OpenAPI/Swagger** integrada
- **Configuração por ambiente** (desenvolvimento, produção, teste)
- **Contêinerização** com Docker e Docker Compose
- **Testes abrangentes** unitários e de integração

## 🏗️ Arquitetura

A aplicação segue o padrão feature-first, promovendo separação de preocupações e modularidade:

```
api-dart/
├── bin/              # Ponto de entrada da aplicação
├── lib/
│   ├── core/         # Componentes centrais (config, DI, middleware, etc.)
│   ├── features/     # Módulos de funcionalidades
│   │   ├── auth/     # Autenticação e autorização
│   │   └── generative/ # IA Generativa
│   └── generated_api/ # Código gerado
├── openapi/          # Documentação da API
├── test/             # Testes
└── ...               # Outros arquivos de configuração
```

## 🚀 Início Rápido

### Usando Docker (Recomendado)

1. **Clone o repositório**

```bash
git clone https://github.com/seu-usuario/api-dart.git
cd api-dart
```

2. **Configure o ambiente**

```bash
cp .env.example .env.development
# Edite .env.development com suas chaves de API e configurações
```

3. **Execute com Docker Compose**

```bash
docker-compose up -d
```

4. **Acesse os serviços**

- **API**: http://localhost:8081
- **Documentação (Swagger)**: http://localhost:8083
- **Gerenciador de DB (Adminer)**: http://localhost:8082

### Localmente

1. **Pré-requisitos**: Dart SDK 3.0+, PostgreSQL (opcional), Redis (opcional)

2. **Instale dependências**

```bash
dart pub get
```

3. **Configure o ambiente**

```bash
cp .env.example .env
# Edite .env com suas configurações
```

4. **Execute a aplicação**

```bash
dart run bin/server.dart
```

## 📋 Endpoints da API

### Autenticação

- `POST /api/v1/auth/register` - Registre um novo usuário
- `POST /api/v1/auth/login` - Autentique e receba um token JWT
- `POST /api/v1/auth/refresh` - Atualize um token JWT
- `POST /api/v1/auth/logout` - Invalide um token

### IA Generativa

- `POST /api/v1/generate/text` - Gere texto a partir de um prompt
- `POST /api/v1/generate/text/stream` - Stream de texto gerado em tempo real
- `POST /api/v1/generate/chat` - Continue uma conversa com IA
- `POST /api/v1/generate/chat/stream` - Stream de respostas de chat em tempo real
- `GET /api/v1/generate/info` - Informações sobre o modelo atual
- `POST /api/v1/generate/cache/clear` - Limpe o cache de respostas

## 🔧 Configuração

A aplicação usa arquivos `.env` para diferentes ambientes. Variáveis importantes incluem:

```env
# Servidor
SERVER_PORT=8080
LOG_LEVEL=INFO
ENVIRONMENT=development

# JWT
JWT_SECRET="sua_chave_secreta"
JWT_EXPIRATION_HOURS=24

# AI Provider (gemini ou openrouter)
AI_PROVIDER=gemini

# Gemini API
GEMINI_API_KEY="sua_chave_api_gemini"
GEMINI_MODEL="gemini-1.5-flash-latest"
GEMINI_MAX_TOKENS=2048
GEMINI_TEMPERATURE=0.7
GEMINI_SAFETY_HARASSMENT=BLOCK_MEDIUM_AND_ABOVE
GEMINI_SAFETY_HATE_SPEECH=BLOCK_MEDIUM_AND_ABOVE
GEMINI_SAFETY_SEXUALLY_EXPLICIT=BLOCK_MEDIUM_AND_ABOVE
GEMINI_SAFETY_DANGEROUS=BLOCK_MEDIUM_AND_ABOVE
GEMINI_ENABLE_STREAMING=true

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=api_dart
DB_USERNAME=postgres
DB_PASSWORD=postgres
```

## 🧪 Testes

Execute os testes com:

```bash
dart test
```

Para ver a cobertura de testes:

```bash
dart run coverage:test_with_coverage
```

## 📚 Exemplos de Uso

### Gerando Texto

```bash
curl -X POST http://localhost:8081/api/v1/generate/text \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer seu_token_jwt" \
  -d '{"prompt": "Explique como fazer uma API em Dart"}'
```

### Streaming de Chat

```javascript
// JavaScript (front-end)
const eventSource = new EventSource('http://localhost:8081/api/v1/generate/chat/stream');
eventSource.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.chunk) {
    // Processar cada chunk de texto recebido
    console.log(data.chunk);
  }
};
```

## 🛠️ Tecnologias

- **Dart** e framework **Shelf**
- **PostgreSQL** para persistência
- **JWT** para autenticação
- **Google Gemini API** para IA generativa
- **OpenAPI/Swagger** para documentação
- **Docker** para containerização

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor, siga estes passos:

1. Faça um fork do repositório
2. Crie uma nova branch (`git checkout -b feature/nova-funcionalidade`)
3. Faça commit das suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Envie para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🙏 Agradecimentos

- A comunidade Dart por fornecer excelentes ferramentas
- Todos os contribuidores que ajudaram a melhorar este projeto

---

⭐ **Gostou deste projeto? Dê uma estrela!** ⭐