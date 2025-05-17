#!/bin/bash

# Script para verificar se há referências restantes ao nome antigo do pacote
echo "Verificando referências restantes a 'api_dart' no código-fonte..."

# Procurando em arquivos Dart
echo "Verificando arquivos Dart..."
DART_REFS=$(grep -r "api_dart" --include="*.dart" . | wc -l)
echo "Encontradas $DART_REFS referências em arquivos Dart"
grep -r "api_dart" --include="*.dart" .

# Procurando em arquivos de configuração
echo -e "\nVerificando arquivos de configuração..."
CONFIG_REFS=$(grep -r "api_dart" --include="*.yaml" --include="*.json" --include="*.env*" . | wc -l)
echo "Encontradas $CONFIG_REFS referências em arquivos de configuração"
grep -r "api_dart" --include="*.yaml" --include="*.json" --include="*.env*" .

# Procurando em arquivos Markdown e outros documentos
echo -e "\nVerificando arquivos de documentação..."
DOC_REFS=$(grep -r "api_dart" --include="*.md" --include="*.txt" . | wc -l)
echo "Encontradas $DOC_REFS referências em arquivos de documentação"
grep -r "api_dart" --include="*.md" --include="*.txt" .

echo -e "\nVerificação concluída."
TOTAL=$((DART_REFS + CONFIG_REFS + DOC_REFS))
echo "Total de referências encontradas: $TOTAL"

if [ $TOTAL -gt 0 ]; then
  echo "ATENÇÃO: Ainda existem referências ao nome antigo do pacote. Verifique os resultados acima."
  exit 1
else
  echo "Parabéns! Não foram encontradas referências ao nome antigo do pacote."
  exit 0
fi 