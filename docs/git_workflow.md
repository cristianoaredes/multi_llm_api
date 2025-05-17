# Fluxo de Trabalho Git

Este projeto segue o modelo GitFlow, que proporciona um fluxo de trabalho organizado para o desenvolvimento, lançamento e manutenção do software.

## Branches Principais

### `main`
- Contém o código de produção
- Sempre estável e pronto para deploy
- Nunca recebe commits diretos (exceto hotfixes em emergências)
- Cada commit na `main` é uma versão de produção e recebe uma tag de versão

### `develop`
- Branch principal de desenvolvimento
- Contém todas as funcionalidades aprovadas e prontas para o próximo release
- Base para branches de feature

## Branches Auxiliares

### `feature/*`
- Criada a partir de: `develop`
- Mesclada de volta para: `develop`
- Convenção de nomenclatura: `feature/nome-da-funcionalidade`
- Usada para desenvolver novas funcionalidades
- Existe apenas durante o desenvolvimento da funcionalidade
- Deve ser mesclada com `develop` via pull request

### `release/*`
- Criada a partir de: `develop`
- Mesclada para: `main` e `develop`
- Convenção de nomenclatura: `release/vX.Y.Z`
- Usada para preparar uma nova versão de produção
- Permite correções de bugs menores e ajustes para produção
- Quando a release estiver pronta, será mesclada em `main` e receberá uma tag de versão
- Quaisquer correções também são mescladas de volta em `develop`

### `hotfix/*`
- Criada a partir de: `main`
- Mesclada para: `main` e `develop`
- Convenção de nomenclatura: `hotfix/vX.Y.Z` ou `hotfix/descricao-breve`
- Usada para corrigir rapidamente bugs críticos em produção
- Quando concluída, é mesclada tanto em `main` (recebendo uma tag de versão) quanto em `develop`

## Fluxo de Trabalho

1. **Desenvolvimento de Funcionalidade**
   - Crie uma nova branch: `git checkout -b feature/nome-da-funcionalidade develop`
   - Implemente a funcionalidade com commits regulares
   - Quando concluída, mescle de volta para `develop`: 
     - `git checkout develop`
     - `git merge --no-ff feature/nome-da-funcionalidade`
     - `git push origin develop`

2. **Criação de Release**
   - Quando `develop` estiver pronta para uma release:
     - `git checkout -b release/vX.Y.Z develop`
     - Faça testes finais, ajustes de documentação e pequenas correções
     - Quando pronta, mescle para `main` e `develop`:
       - `git checkout main`
       - `git merge --no-ff release/vX.Y.Z`
       - `git tag -a vX.Y.Z -m "Versão X.Y.Z"`
       - `git checkout develop`
       - `git merge --no-ff release/vX.Y.Z`

3. **Correção de Bugs em Produção (Hotfix)**
   - Quando um bug crítico é encontrado em produção:
     - `git checkout -b hotfix/descricao main`
     - Faça as correções necessárias
     - Mescle para `main` e `develop`:
       - `git checkout main`
       - `git merge --no-ff hotfix/descricao`
       - `git tag -a vX.Y.Z+1 -m "Versão X.Y.Z+1"`
       - `git checkout develop`
       - `git merge --no-ff hotfix/descricao`

## Boas Práticas

- Sempre faça pull antes de criar uma nova branch
- Mantenha as branches curtas e focadas em uma única funcionalidade/correção
- Escreva mensagens de commit descritivas e significativas
- Use pull requests para mesclar branches de funcionalidades
- Faça code reviews regulares
- Execute testes antes de mesclar para branches principais

## Padrão de Commits

Adotamos o padrão de commits convencionais para mensagens de commit claras e consistentes:

- `feat:` - Nova funcionalidade
- `fix:` - Correção de bug
- `docs:` - Alteração de documentação
- `style:` - Formatação, ponto e vírgula ausente, etc. (sem alteração de código)
- `refactor:` - Refatoração de código
- `test:` - Adição ou correção de testes
- `chore:` - Alterações diversas que não modificam código fonte

Exemplo: `feat: adiciona endpoint de streaming para geração de texto` 