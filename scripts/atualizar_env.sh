#!/bin/bash

# Script para atualizar os nomes de banco de dados nos arquivos de ambiente
echo "Atualizando nomes de banco de dados nos arquivos de ambiente..."

# Atualiza .env se existir
if [ -f ".env" ]; then
  sed -i '' 's/DB_NAME=api_dart/DB_NAME=multi_llm_api/g' .env
  echo "Atualizado: .env"
fi

# Atualiza .env.development se existir
if [ -f ".env.development" ]; then
  sed -i '' 's/DB_NAME=api_dart/DB_NAME=multi_llm_api/g' .env.development
  echo "Atualizado: .env.development"
fi

# Atualiza .env.production se existir
if [ -f ".env.production" ]; then
  sed -i '' 's/DB_NAME=api_dart_prod/DB_NAME=multi_llm_api_prod/g' .env.production
  echo "Atualizado: .env.production"
fi

# Atualiza .env.example
if [ -f ".env.example" ]; then
  sed -i '' 's/DB_NAME=api_dart/DB_NAME=multi_llm_api/g' .env.example
  echo "Atualizado: .env.example"
fi

echo "Atualização dos arquivos de ambiente concluída!"
echo "Lembre-se de verificar os arquivos e ajustar outros valores se necessário." 