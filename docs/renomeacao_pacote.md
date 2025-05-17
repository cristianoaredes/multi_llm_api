# Renomeação do Pacote

Data: **28/05/2024**

Este documento descreve o processo de renomeação do pacote de `api_dart` para `multi_llm_api`, realizado como parte da padronização e rebranding do projeto.

## Razão

A renomeação foi necessária para:
1. Refletir com mais precisão o propósito do projeto como gateway para múltiplos LLMs
2. Adotar um nome mais descritivo e profissional
3. Evitar ambiguidades com outros projetos Dart

## Ações Realizadas

### 1. Atualização de Arquivos de Configuração

- [x] Atualizado o nome do pacote no `pubspec.yaml`
- [x] Atualizado o arquivo `.dart_tool/package_config.json` (via `dart pub get`)
- [x] Atualizado o valor padrão do nome do banco de dados em `env_config.dart`
- [x] Renomeado o arquivo `lib/generated_api/api_dart.dart` para `lib/generated_api/multi_llm_api.dart`

### 2. Atualização de Importações

Um script automatizado foi usado para atualizar todas as referências:

```bash
#!/bin/bash

# Script para renomear as importações do pacote de api_dart para multi_llm_api
echo "Iniciando renomeação do pacote de api_dart para multi_llm_api"

# Verificar se o diretório está correto
if [ ! -d "lib" ] || [ ! -d "test" ]; then
  echo "Erro: Este script deve ser executado no diretório raiz do projeto"
  exit 1
fi

# Função para processar arquivos encontrados
process_files() {
  local dir=$1
  local count=0
  
  echo "Processando arquivos em $dir..."
  
  # Encontra todos os arquivos Dart e substitui as importações
  find "$dir" -type f -name "*.dart" | while read file; do
    # Verifica se o arquivo contém importações do pacote antigo
    if grep -q "package:api_dart/" "$file"; then
      # Substitui todas as ocorrências
      sed -i '' 's/package:api_dart\//package:multi_llm_api\//g' "$file"
      count=$((count + 1))
      echo "Atualizado: $file"
    fi
  done
  
  echo "Total de arquivos atualizados em $dir: $count"
}

# Processar diretórios principais
process_files "lib"
process_files "test"
process_files "bin"
process_files "examples"

echo "Renomeação concluída!"
```

> Nota: Este script foi executado em 28/05/2024 e completou com sucesso a renomeação das importações no código.

### 3. Atualização de Outros Identificadores

- [x] Atualizado issuer nos tokens JWT de `api_dart` para `multi_llm_api`
- [x] Atualizado comentários e documentação no código
- [x] Corrigidas referências em exemplos e testes

### 4. Atualização de Outros Identificadores

- [x] Atualizado issuer nos tokens JWT de `api_dart` para `multi_llm_api`
- [x] Atualizado comentários e documentação no código
- [x] Corrigidas referências em exemplos e testes

### 5. Verificação Pós-Renomeação

- [x] Verificado referências restantes ao nome antigo usando `grep -r "api_dart" --include="*.dart" .`
- [x] Executado `dart pub get` para atualizar o cache do Dart
- [x] Executado `dart analyze` para verificar problemas de compilação
- [x] Criado script de verificação para buscar referências perdidas

## Impacto

A renomeação do pacote não alterou a funcionalidade do código, mas trouxe os seguintes benefícios:

1. Nome mais descritivo e profissional para a API
2. Melhor alinhamento com o propósito da plataforma (múltiplos LLMs)
3. Remoção de ambiguidades com outros projetos Dart

## Exemplos de Alteração

Antes:
```dart
   import 'package:api_dart/...';
```

Depois:
```dart
   import 'package:multi_llm_api/...';
```

## Limitações e Ressalvas

- Existem vários warnings de análise no código, mas não estão relacionados ao nome do pacote
- A documentação no código pode conter algumas referências ao nome antigo em comentários de texto (sem impacto funcional)

## Impacto nas Implementações Existentes

Para clientes que já estavam utilizando o pacote, as seguintes atualizações são necessárias:

1. Atualizar referências de importação:
   ```dart
   // Antes
   import 'package:api_dart/...';
   
   // Depois
   import 'package:multi_llm_api/...';
   ```

2. Atualizar referências ao nome do banco de dados (caso esteja usando o padrão)

3. Atualizar referências ao nome do emissor em verificações de token JWT (se aplicável)

## Próximos Passos

- Verificar e atualizar documentação externa que faz referência ao pacote
- Considerar criar um script para ajudar clientes na migração (se necessário)
- Verificar eventuais ocorrências do nome antigo nos testes e exemplos 