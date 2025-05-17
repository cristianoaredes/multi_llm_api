# Atualizações recomendadas para o arquivo .env.example

Adicione as seguintes configurações após o bloco de configuração do GEMINI_TEMPERATURE:

```
# Gemini Safety Settings (Options: BLOCK_NONE, BLOCK_LOW_AND_ABOVE, BLOCK_MEDIUM_AND_ABOVE, BLOCK_ONLY_HIGH)
GEMINI_SAFETY_HARASSMENT=BLOCK_MEDIUM_AND_ABOVE
GEMINI_SAFETY_HATE_SPEECH=BLOCK_MEDIUM_AND_ABOVE
GEMINI_SAFETY_SEXUALLY_EXPLICIT=BLOCK_MEDIUM_AND_ABOVE
GEMINI_SAFETY_DANGEROUS=BLOCK_MEDIUM_AND_ABOVE
# Habilitar streaming de resposta para geração de texto e chat
GEMINI_ENABLE_STREAMING=true
```

Estas configurações:
1. Definem níveis de segurança para diferentes categorias de conteúdo potencialmente prejudicial
2. Habilitam o streaming de resposta da API Gemini para experiência em tempo real 