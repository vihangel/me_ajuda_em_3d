<!-- @format -->

# TODO — Me Ajuda em 3D

## Análise do estado atual

O projeto tem uma boa base: Flutter com arquitetura limpa (core/data/features),
API Node.js com Express + MongoDB, e separação clara entre rota pública (pedido
do cliente) e admin. Porém tudo roda com dados fake em memória no Flutter e a
API não cobre todos os módulos.

---

## Problemas encontrados

### Estrutura / Arquitetura

- [ ] Flutter usa `InMemoryOperationRepository` — nada persiste
- [ ] Não existe `ApiOperationRepository` para conectar na API real
- [ ] Não há pacote HTTP no pubspec.yaml (falta `http` ou `dio`)
- [ ] Não há configuração de base URL da API no Flutter
- [ ] `main.dart` não existe — o entry point é `bootstrap.dart` mas falta o `main.dart` padrão

### API (apps/api)

- [ ] Faltam endpoints para: quotes, jobs, dashboard summary, supplies, templates
- [ ] Endpoint `PATCH /jobs/:id/status` mencionado no README não existe
- [ ] Endpoint `PATCH /customer-orders/:id/status` não existe (admin precisa mudar status)
- [ ] Endpoint `PATCH /materials/:id` não existe (atualizar estoque)
- [ ] Não há validação de input nos endpoints (qualquer body é aceito)
- [ ] Não há endpoint para supplies (insumos)
- [ ] Busca global retorna formato diferente do que o Flutter espera

### Flutter — Telas

- [ ] Calculadora 3D não existe (mencionada como requisito)
- [ ] Tela de Settings está como placeholder vazio
- [ ] Botão "Criar orçamento" no QuoteEditor só fecha o modal, não salva
- [ ] Botões "Atualizar cliente" e "Pronto para retirada" na produção são `showComingSoon`
- [ ] Upload de imagem de referência é fake (só muda um boolean)
- [ ] Busca global e notificações usam dados fake

### Qualidade de código

- [ ] `DropdownButtonFormField` usa `initialValue` (não existe) em vez de `value`
- [ ] Nenhum tratamento de erro HTTP no Flutter
- [ ] Sem loading states durante chamadas de API
- [ ] Sem retry/refresh após criar pedido/cliente/material

---

## Melhorias a implementar

### P0 — Crítico (conectar ao backend real)

- [x] Adicionar pacote `http` ao pubspec.yaml
- [x] Criar `lib/core/api_config.dart` com base URL configurável
- [x] Criar `lib/data/api_operation_repository.dart` conectando na API
- [x] Trocar `InMemoryOperationRepository` por `ApiOperationRepository` no app.dart
- [x] Adicionar endpoints faltantes na API (quotes, jobs, dashboard, supplies)
- [x] Adicionar `main.dart` como entry point padrão

### P1 — Funcionalidades faltantes

- [x] Criar tela de Calculadora 3D (usa `calculateQuoteTotals` que já existe)
- [x] Adicionar calculadora como tab no admin
- [x] Adicionar endpoint `PATCH /customer-orders/:id/status`
- [x] Adicionar endpoint `PATCH /materials/:id`

### P2 — Qualidade

- [x] Corrigir `DropdownButtonFormField` (trocar `initialValue` por `value`)
- [ ] Adicionar validação de formulários
- [ ] Melhorar tratamento de erros nas chamadas HTTP
- [ ] Adicionar pull-to-refresh nas listas

### P3 — Nice to have

- [ ] Autenticação admin (pelo menos senha simples)
- [ ] Upload real de imagens via API
- [ ] Integração Mercado Pago
- [ ] Push notifications
- [ ] Tema escuro
