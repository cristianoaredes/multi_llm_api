# Diretrizes de Desenvolvimento

Este documento estabelece as diretrizes e melhores práticas para o desenvolvimento do projeto MultiLLM API.

## Arquitetura e Organização de Código

### Estrutura de Diretórios

O projeto segue uma abordagem **feature-first**, onde o código é organizado principalmente por funcionalidade e não por tipo técnico. Isso promove:

- Maior coesão entre componentes relacionados
- Facilidade de localização do código
- Encapsulamento de recursos específicos

```
lib/
├── core/                  # Componentes centrais, compartilhados por todo o app
│   ├── config/            # Configurações da aplicação
│   ├── di/                # Injeção de dependência
│   ├── error/             # Tratamento de erros
│   ├── logging/           # Configuração de logs
│   ├── middleware/        # Middlewares comuns
│   ├── presentation/      # DTOs e componentes de apresentação comuns
│   ├── server/            # Configuração do servidor
│   ├── services/          # Serviços compartilhados
│   └── utils/             # Utilitários comuns
│
├── features/              # Módulos de funcionalidades
│   ├── feature1/          # Uma funcionalidade específica
│   │   ├── data/          # Camada de dados (models, repositories, sources)
│   │   │   ├── models/    # Entidades de dados
│   │   │   └── repositories/ # Implementações de repositórios
│   │   ├── domain/        # Lógica de negócios (services, interfaces)
│   │   │   └── interfaces/ # Contratos/interfaces
│   │   └── presentation/  # Expõe funcionalidades (handlers, DTOs)
│   │       └── dtos/      # Objetos de transferência de dados
│   └── feature2/...       # Outra funcionalidade
│
└── generated_api/        # Código gerado automaticamente
```

### Camadas da Arquitetura

Cada feature deve seguir uma arquitetura em camadas:

1. **Camada de Apresentação (Presentation)**
   - Manipuladores HTTP (Handlers)
   - DTOs (Data Transfer Objects)
   - Transformação/Validação de dados

2. **Camada de Domínio (Domain)**
   - Regras de negócio
   - Services
   - Interfaces/Contratos

3. **Camada de Dados (Data)**
   - Modelos
   - Repositórios
   - Fontes de dados

### Injeção de Dependência

Utilize o padrão de Injeção de Dependência para:
- Facilitar testes
- Reduzir acoplamento
- Promover manutenibilidade

Exemplo:
```dart
// Arquivo features/feature/feature_injector.dart
void setupFeatureInjector(GetIt injector) {
  // Registrar repositórios
  injector.registerSingleton<IFeatureRepository>(
    FeatureRepository(),
  );
  
  // Registrar serviços
  injector.registerSingleton<IFeatureService>(
    FeatureService(injector<IFeatureRepository>()),
  );
}
```

## Padrões de Código

### Diretrizes Gerais

1. **Nomes Significativos**
   - Classes: `PascalCase`
   - Métodos/variáveis: `camelCase`
   - Constantes: `SCREAMING_SNAKE_CASE` ou `kConstantName`

2. **Documentação**
   - Adicione documentação em dart-doc para todas as classes públicas e métodos
   - Inclua exemplos de uso quando apropriado

3. **Formatação**
   - Utilize `dart format` para padronização
   - Respeite as regras do `analysis_options.yaml`

4. **Princípios SOLID**
   - S: Responsabilidade Única
   - O: Aberto para extensão, fechado para modificação
   - L: Substituição de Liskov
   - I: Segregação de Interfaces
   - D: Inversão de Dependência

### DTOs e Serialização

- Defina DTOs (Data Transfer Objects) para entrada e saída
- Use anotações JSON para serialização/desserialização
- Implementar validação dentro de métodos `fromJson` dos DTOs

Exemplo:
```dart
@JsonSerializable()
class FeatureRequestDto {
  final String name;
  final int count;

  FeatureRequestDto({required this.name, required this.count});

  factory FeatureRequestDto.fromJson(Map<String, dynamic> json) {
    // Validação
    if (json['name'] == null || json['count'] == null) {
      throw BadRequestException('Missing required fields');
    }
    
    return _$FeatureRequestDtoFromJson(json);
  }

  Map<String, dynamic> toJson() => _$FeatureRequestDtoToJson(this);
}
```

## Tratamento de Erros

- Utilize exceções específicas para diferentes tipos de erro
- Centralize o tratamento de exceções no middleware
- Forneça mensagens de erro claras e informativas

```dart
// Hierarquia de exceções
abstract class AppException implements Exception {
  final String message;
  final int statusCode;
  
  AppException(this.message, {required this.statusCode});
}

class BadRequestException extends AppException {
  BadRequestException(String message) : super(message, statusCode: 400);
}

class UnauthorizedException extends AppException {
  UnauthorizedException(String message) : super(message, statusCode: 401);
}
```

## Testes

### Tipos de Testes

1. **Testes Unitários**
   - Teste cada unidade isoladamente
   - Use mocks para dependências
   - Foco em cobertura de casos de borda

2. **Testes de Integração**
   - Teste a interação entre componentes
   - Inclua testes HTTP end-to-end

3. **Testes de Performance**
   - Meça e estabeleça limites para operações críticas

### Diretrizes para Testes

- Mantenha testes independentes (sem dependências entre testes)
- Siga o padrão Arrange-Act-Assert
- Mire em alta cobertura (>80% para lógica de negócios)
- Teste tanto casos de sucesso quanto de falha

Exemplo:
```dart
group('FeatureService', () {
  late MockFeatureRepository mockRepository;
  late FeatureService service;
  
  setUp(() {
    mockRepository = MockFeatureRepository();
    service = FeatureService(mockRepository);
  });
  
  test('should return features when repository succeeds', () async {
    // Arrange
    when(mockRepository.getFeatures())
        .thenAnswer((_) async => [Feature(id: '1', name: 'Test')]);
    
    // Act
    final result = await service.getFeatures();
    
    // Assert
    expect(result, isA<List<Feature>>());
    expect(result.length, 1);
    expect(result[0].name, 'Test');
  });
});
```

## Segurança

### Sanitização de Entrada

- Sanitize toda entrada de usuário para prevenir ataques de injeção
- Use o middleware de sanitização para processar automaticamente solicitações JSON

### Autenticação e Autorização

- Use tokens JWT para autenticação
- Implemente middleware de autenticação para proteger rotas
- Separe rotas públicas de privadas claramente

### Proteção de Dados

- Nunca armazene segredos no código-fonte
- Use variáveis de ambiente para configuração
- Implemente tratamento seguro de senhas (hashing)

## Processo de Desenvolvimento

### Fluxo de Trabalho Git

1. Siga o modelo GitFlow
   - `main`: código de produção
   - `develop`: código em desenvolvimento
   - `feature/*`: novas funcionalidades
   - `release/*`: preparação para lançamentos
   - `hotfix/*`: correções urgentes

2. Padrão de commits:
   - `feat:` Nova funcionalidade
   - `fix:` Correção de bug
   - `docs:` Documentação
   - `test:` Adicionando/corrigindo testes
   - `refactor:` Refatoração de código
   - `perf:` Melhorias de performance
   - `chore:` Tarefas de manutenção

### Pull Requests e Code Reviews

- Crie PRs descritivos com informações sobre o que/como/por que
- Configure CI para executar testes e análise de código automaticamente
- Obtenha pelo menos uma aprovação antes de mesclar
- Resolva todos os comentários da revisão

## Performance e Escalabilidade

- Implemente caching para operações frequentes
- Use técnicas assíncronas e streaming quando apropriado
- Evite bloqueio de thread principal
- Mantenha bibliotecas atualizadas

## Documentação

- Mantenha a documentação OpenAPI/Swagger atualizada
- Documente configurações e variáveis de ambiente
- Inclua diagramas de arquitetura quando útil
- Mantenha o README atualizado com instruções de execução 