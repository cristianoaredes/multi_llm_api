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
      echo "  Atualizado: $file"
    fi
  done
  
  echo "Concluído: $count arquivo(s) atualizado(s) em $dir"
}

# Processar diretórios principais
process_files "lib"
process_files "bin"
process_files "test"

echo "Renomeação do pacote concluída!"
echo "Execute 'dart pub get' para atualizar as dependências." 