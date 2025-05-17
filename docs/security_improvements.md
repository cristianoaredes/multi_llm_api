# Melhorias de Segurança na API

Este documento descreve as melhorias de segurança implementadas na API Multi-LLM.

## Data: 10/06/2024

## Resumo das Melhorias

### 1. Sanitização de Entradas

Implementamos uma camada robusta de sanitização de entradas para proteger contra diversos tipos de ataques de injeção:

- **Middleware de Sanitização**: Intercepta todas as requisições POST, PUT e PATCH para sanitizar os corpos JSON antes do processamento.
- **Utilitário de Sanitização**: Fornece métodos específicos para diferentes tipos de dados (SQL, HTML, caminhos de arquivo, etc.).
- **Sanitização Recursiva**: Processa estruturas JSON aninhadas para garantir que todos os dados sejam sanitizados.

### 2. Configurações de Segurança do Gemini

Implementamos configurações de segurança personalizáveis para a API Gemini:

- **SafetySettings**: Configuração de limites de bloqueio para diferentes categorias de conteúdo prejudicial:
  - Assédio (Harassment)
  - Discurso de ódio (Hate Speech)
  - Conteúdo sexualmente explícito (Sexually Explicit)
  - Conteúdo perigoso (Dangerous Content)

- **Configuração via Variáveis de Ambiente**: As configurações de segurança são definidas no arquivo `.env`, permitindo ajustes sem modificação do código.

### 3. Pipeline de Processamento Seguro

Estruturamos a pipeline de processamento de requisições para garantir segurança em camadas:

1. **Sanitização** (primeiro middleware a ser executado)
2. **Validação** (verificação de formato e requisitos)
3. **Autenticação** (verificação de identidade)
4. **Limitação de Taxa** (prevenção de abuso)
5. **Processamento de negócios** (handlers específicos)

## Testes

Implementamos testes abrangentes para garantir a eficácia das medidas de segurança:

- **Testes Unitários**: Testam individualmente cada componente de segurança
- **Testes de Integração**: Verificam se o sistema completo está protegido

## Uso das Configurações de Segurança

Para configurar os níveis de segurança do Gemini, ajuste as seguintes variáveis no arquivo `.env`:

```env
# Opções: BLOCK_NONE, BLOCK_LOW_AND_ABOVE, BLOCK_MEDIUM_AND_ABOVE, BLOCK_ONLY_HIGH
GEMINI_SAFETY_HARASSMENT=BLOCK_MEDIUM_AND_ABOVE
GEMINI_SAFETY_HATE_SPEECH=BLOCK_MEDIUM_AND_ABOVE
GEMINI_SAFETY_SEXUALLY_EXPLICIT=BLOCK_MEDIUM_AND_ABOVE
GEMINI_SAFETY_DANGEROUS=BLOCK_MEDIUM_AND_ABOVE
```

## Próximos Passos

- Implementar análise de segurança contínua via CI/CD
- Adicionar monitoramento de tentativas de ataque
- Implementar rotação automática de chaves de API 